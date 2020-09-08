terraform {
  source = ".//tf"
}

include {
  path = "${find_in_parent_folders()}"
}
