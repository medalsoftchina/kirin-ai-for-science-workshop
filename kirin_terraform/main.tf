# =============================================================================
# Day2 Lab 0: Azure AI Foundry 環境構築 (Kirin ワークショップ)
#
# 検証済み AVM パターンモジュール
#   Azure/avm-ptn-aiml-ai-foundry/azurerm (0.11.3)
# を使い、AI Foundry アカウント + プロジェクト + 依存リソース
# (AI Search / Storage / Key Vault / Cosmos DB) をまとめてデプロイします。
# =============================================================================

provider "azurerm" {
  features {
    # ハンズオン終了後に terraform destroy で確実に消せるようにする設定
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      # destroy 時に Key Vault を論理削除ではなく完全削除 (パージ) する。
      # これを有効にしないと、同じ名前で再デプロイしたときに
      # 「ソフト削除済みの同名 Vault が存在する」エラーになります。
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azapi" {}

# -----------------------------------------------------------------------------
# リソースグループ (rg-kirinws)
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.base_name}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Azure AI Foundry (AVM パターンモジュール)
# -----------------------------------------------------------------------------
module "ai_foundry" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.11.3"

  base_name                  = var.base_name
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  tags                       = var.tags

  # create_byor = true: 依存リソース (AI Search / Storage / Key Vault /
  # Cosmos DB) をこのモジュールが新規作成するモード (CYOR: Create Your Own
  # Resources)。false にすると既存リソースの ID 指定 (BYOR) が必要です。
  create_byor              = true
  create_private_endpoints = false # プライベートエンドポイントは作成しない (ラボのため最小構成)

  # Agent Service を有効化 (既定は false)。これを true にすると Capability Host が
  # 作成され、Agent のスレッド状態が Cosmos DB に永続化される (Lab 3 の裏側)。
  # 既定のままだと Cosmos DB は作成されるだけで使われないので注意。
  ai_foundry = {
    create_ai_agent_service = true
  }

  # AVM のテレメトリ (Microsoft への匿名の利用統計) を無効化し、
  # 作成されるリソース数を最小限に抑えます。
  enable_telemetry = false

  # --- AI Foundry プロジェクト (kirin-rnd-lab) -------------------------------
  ai_projects = {
    lab = {
      name         = var.project_name
      display_name = var.project_name
      description  = "Kirin R&D ワークショップ用 AI Foundry プロジェクト (Day2 Lab 0)"
      # プロジェクトと依存リソースの接続 (コネクション) を作成する
      create_project_connections = true
      cosmos_db_connection = {
        new_resource_map_key = "this"
      }
      ai_search_connection = {
        new_resource_map_key = "this"
      }
      key_vault_connection = {
        new_resource_map_key = "this"
      }
      storage_account_connection = {
        new_resource_map_key = "this"
      }
    }
  }

  # --- 依存リソースの定義 (モジュールが新規作成) ------------------------------
  # AI Search: Basic SKU / レプリカ 1 (コスト最小構成。約 $75/月 課金に注意)
  ai_search_definition = {
    this = {
      sku             = "basic"
      replica_count   = 1
      partition_count = 1
    }
  }

  # Storage アカウント: LRS (ローカル冗長、最小コスト)
  storage_account_definition = {
    this = {
      account_replication_type = "LRS"
      # 共有キー認証を有効化。モジュール既定は false (セキュリティ強化) だが、
      # false のままだと azurerm プロバイダーがデータプレーン (queue properties) を
      # 読めず apply が 403 で失敗するため、ラボでは true とする。
      # 本番環境では false (AAD 認証のみ) を推奨。
      shared_access_key_enabled = true
    }
  }

  # Key Vault: 既定 (standard SKU)。destroy 時の完全削除は上の
  # provider ブロックの purge_soft_delete_on_destroy = true で実現。
  key_vault_definition = {
    this = {}
  }

  # Cosmos DB: エージェントのスレッド状態保存用 (既定構成で作成)
  cosmosdb_definition = {
    this = {
      # Agent Service の Capability Host (パブリック構成) は Cosmos DB への
      # パブリックアクセスを要求する。モジュール既定 (false) のままだと
      # Agent 作成が cosmos_vnet_blocked で失敗する (2026-09-29 実測)。
      public_network_access_enabled = true
    }
  }

  # --- モデルデプロイ (3 モデル) ----------------------------------------------
  # 2026-09-28 に Medalsoft Demo サブスクリプション (japaneast) で
  # 利用可能であることを確認済みの最新モデル:
  #   gpt-6-luna 2026-09-22 (主力チャット) / gpt-5.6-terra 2026-07-09 (比較用)
  #   ※ gpt-6-terra は未提供のため、比較用は最新の terra 系 (5.6) を使用
  ai_model_deployments = {
    "gpt-6-luna" = {
      name = "gpt-6-luna"
      model = {
        format  = "OpenAI"
        name    = "gpt-6-luna"
        version = "2026-09-22"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10000
      }
    }
    "gpt-5.6-terra" = {
      name = "gpt-5.6-terra"
      model = {
        format  = "OpenAI"
        name    = "gpt-5.6-terra"
        version = "2026-07-09"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10000
      }
    }
    "text-embedding-3-large" = {
      name = "text-embedding-3-large"
      model = {
        format  = "OpenAI"
        name    = "text-embedding-3-large"
        version = "1"
      }
      scale = {
        type     = "Standard"
        capacity = 1000
      }
    }
    # --- Agent Service 互換性メモ (2026-09-28 実測) ---------------------------
    # gpt-6 系 (luna/sol/astra) と gpt-5.6 系 (terra/luna) はチャット完了 API
    # では動作するが、Agent Service の run は失敗する (top_p 非対応 /
    # server_error)。そのため Lab 3 (Agent Service) は最新 GA の gpt-4.1 を
    # 使用し、プレビュー系はポータル (Playground / ナレッジベース) で使う。
    "gpt-4.1" = {
      name = "gpt-4.1"
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
      scale = {
        type     = "GlobalStandard"
        capacity = 10000
      }
    }
  }
}
