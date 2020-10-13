variable "public_key_johannes" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC0Vt+YejjXH2MNJwUjpSceDyFGpVW0J0B+cmpVNFvnxf8dzfJ93xPmrn6uGS2EW/Y8D28iqf2jG5jJdtYcfdyl8CUQlc34FIgTdLdJuvXTbHZjlKLRfNZDJB/j83ARsBxbYi6Ok3UXiLOjRpBJU3UaqbbRQQFaRSjoa6SiAkeCCd6B4zG3mbwqovuv+kHu6VdwjdZxWAZ2DVeZbYU/7u5G2loLuyQyXupLs3YrIkpWnJnQdm8X3YZt6L/4kcj8Pcibag0qN0lxM6vizhNrFgD3N/3y7eTuwRn82CAgezG9aeaK/3cEJVnAg/G3MmpSz6xR7fKnbSQF+XGqHWT6hHN johannes@Johanness-MacBook-Pro.local"
}

resource "exoscale_ssh_keypair" "johannes" {
  name       = "johannes"
  public_key = var.public_key_johannes
}