# Concourse-vault-traefik

<a rel="noopener noreferrer" target="_blank" href="https://concourse-ci.org">Concourse-CI</a> deployed alongside <a rel="noopener noreferrer" target="_blank" href="https://www.vaultproject.io">Vault</a> inside a <a rel="noopener noreferrer" target="_blank" href="https://www.digitalocean.com">DigitalOcean</a> droplet, behind <a rel="noopener noreferrer" target="_blank" href="https://traefik.io">Træfik</a>.

## Deploy

Deploy with <a rel="noopener noreferrer" target="_blank" href="https://www.terraform.io">Terraform</a>:

1. The simplest way is to create `provide.tfvars` as such:

    ```hcl
    # provide.tfvars
    domain = "example.com"
    records = {
    "ci."    = { "type" = "A", "value" = "droplet", "domain" = "example.com", "ttl" = 86400 }
    "vault." = { "type" = "A", "value" = "droplet", "domain" = "exampleo.com", "ttl" = 86400 }
    }
    user = "concourse-host-user"
    ssh_keys = [123456, "00:00:00:00:00:00:00:00:00:00:00:00:de:ad:be:ef"]
    letsencrypt_admin_email = "postmaster@example.com"
    vault_external_url      = "https://vault.example.com"
    concourse_external_url  = "https://ci.example.com"
    postgres_user           = "concourse"
    ```

2. The `do_token`, `postgres_password` and `concourse_root_password` will be prompted on creation, but again, environment variables are simpler. Below there's code to generate passwords as well.

    ```bash
    ~$ export TF_VAR_do_token=your-digitalocean-token
    ~$ export TF_VAR_postgres_password=$(head /dev/urandom | tr -dc a-zA-Z0-9 | head -c 64)
    ~$ export TF_VAR_concourse_root_password=$(head /dev/urandom | tr -dc a-zA-Z0-9 | head -c 64)
    ```

3. Run initialize terraform, get modules and apply config

    ```bash
    $ terraform init
    ...
    $ terraform get
    ...
    $ terraform apply -var-file=provide.tfvars
    ...
    ```

    Once it finishes the droplet will be online and usable.

## Further configuration

The server is deployed, and the services are working, but `Concourse` is not communicating with `Vault` (yet).

- Initialize `vault`. Save the unseal keys and the root token.

    ```bash
    $ export VAULT_ADDR=https://vault.example.com # your vault_external_url
    $ vault operator init # save this output
    ```

- Unseal `vault`, login and enable the `approle` backend.

    ```bash
    $ vault operator unseal # paste unseal key 1
    $ vault operator unseal # paste unseal key 2
    $ vault operator unseal # paste unseal key 3
    $ vault login           # paste root token
    $ vault policy write concourse ./vault/config/concourse-policy.hcl
    $ vault auth enable approle
    $ vault write auth/approle/role/concourse policies=concourse period=1h
    ```

- Obtain `role_id` and generate a `secret_id`

    ```bash
    $ vault read auth/approle/role/concourse/role-id
    Key        Value
    ---        -----
    role_id    5f3420cd-3c66-2eff-8bcc-0e8e258a7d18
    $ vault write -f auth/approle/role/concourse/secret-id
    Key                   Value
    ---                   -----
    secret_id             f7ec2ac8-ad07-026a-3e1c-4c9781423155
    secret_id_accessor    1bd17fc6-dae1-0c82-d325-3b8f9b5654ee
    ```

- `ssh` into your server (you can find the ip-address with `terraform show`), modify the `docker-compose.yml` to reflect these values

    ```yml
    # docker-compose.yml
    ...
    CONCOURSE_VAULT_URL: https://vault.example.com
    CONCOURSE_VAULT_AUTH_BACKEND: approle
    CONCOURSE_VAULT_AUTH_PARAM: role_id:5f3420cd-3c66-2eff-8bcc-0e8e258a7d18,secret_id:f7ec2ac8-ad07-026a-3e1c-4c9781423155
    ...
    ```

You may need to add policies to give users access to the `/concourse` path. e.g.

```hcl
## concourse-users-policy.hcl
path "concourse/all/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Use templated policies to add a path unique to each user.
# See https://www.vaultproject.io/docs/concepts/policies/#templated-policies
path "concourse/{{identity.entity.id}}" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

```

Save that to `concourse-users-policy.hcl` and enable it with `vault policy write concourse-users concourse-users-policy.hcl`.
