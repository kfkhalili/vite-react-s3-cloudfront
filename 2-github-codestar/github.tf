variable "github_token" {
  description = "GitHub API token"
}

resource "github_repository" "vite_react_app" {
  name = "${lower(replace(var.app_name, " ", "-"))}-vite-react-app"
  description = "${title(replace(var.app_name, "-", " "))} React Vite - Frontend Repository"
  visibility = "private"
}

output "repository_clone_url" {
  value = github_repository.vite_react_app.ssh_clone_url
}

output "repository_name" {
  value = github_repository.vite_react_app.full_name
}