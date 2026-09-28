# =============================================================================
# 入力変数 (terraform.tfvars で上書きできます)
# =============================================================================

variable "base_name" {
  type        = string
  default     = "kirinws"
  description = "リソース名のプレフィックス。リソースグループは rg-<base_name> になります。3〜7文字の小英数字。"

  validation {
    condition     = can(regex("^[a-z0-9]{3,7}$", var.base_name))
    error_message = "base_name は 3〜7 文字の小文字英数字のみで指定してください (例: kirinws)。"
  }
}

variable "location" {
  type        = string
  default     = "japaneast"
  description = "デプロイ先の Azure リージョン。"
}

variable "project_name" {
  type        = string
  default     = "kirin-rnd-lab"
  description = "AI Foundry プロジェクト名。"
}

variable "tags" {
  type        = map(string)
  description = "すべてのリソースに付与するタグ。owner は自分の名前に書き換えてください。"
  default = {
    workload    = "ai-foundry-lab"
    environment = "workshop"
    managed_by  = "terraform"
    day         = "day2-lab0"
    owner       = "your-name"
  }
}
