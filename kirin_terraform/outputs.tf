# =============================================================================
# 出力 (terraform apply 完了後に `terraform output` で確認できます)
# =============================================================================

output "ai_foundry_project_endpoint" {
  description = "AI Foundry プロジェクトのエンドポイント (https://<account>.services.ai.azure.com/api/projects/<project> 形式)。SDK 接続に使用します。"
  value       = "https://${module.ai_foundry.ai_foundry_name}.services.ai.azure.com/api/projects/${module.ai_foundry.ai_foundry_project_name["lab"]}"
}

output "ai_foundry_project_name" {
  description = "AI Foundry プロジェクト名。"
  value       = module.ai_foundry.ai_foundry_project_name["lab"]
}

output "ai_search_endpoint" {
  description = "Azure AI Search のエンドポイント URL。"
  value       = "https://${module.ai_foundry.ai_search_name["this"]}.search.windows.net"
}

output "storage_account_name" {
  description = "Storage アカウント名。"
  value       = module.ai_foundry.storage_account_name["this"]
}

output "resource_group_name" {
  description = "リソースグループ名 (rg-<base_name>)。"
  value       = module.ai_foundry.resource_group_name
}
