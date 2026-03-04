output "static_website_url" {
  description = "Primary endpoint URL for the Azure Storage static website. Use this as the origin when fronting with a CDN or as the direct URL for testing."
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}
