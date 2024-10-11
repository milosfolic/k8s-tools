export K8S_NS=solver-datalake

# Add helm repo
export HELM_REPO_USERNAME=''
export HELM_REPO_PASSWORD=''
helm repo add thingsolver https://registry.see.asseco.com/chartrepo/thingsolver
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install PostgreSQL for ranger
helm -n $K8S_NS upgrade --install datalake bitnami/postgresql --version 11.9.13  \
    --set auth.username=ranger \
    --set auth.password="" \
    --set auth.database=ranger \
    --set auth.postgresPassword=""

# Install keycloak
helm -n $K8S_NS upgrade --install keycloak bitnami/keycloak --version 21.4.1 -f keycloak.yml

# Install Ranger
helm -n $K8S_NS upgrade --install solver-apache-ranger thingsolver/solver-apache-ranger --version 1.4.0 -f ranger.yml

# Create secret with aws access keys
kubectl -n $K8S_NS create secret generic metastore-secrets \
  --from-literal=AWS_DEFAULT_REGION='eu-central-1' \
  --from-literal=AWS_ACCESS_KEY_ID='' \
  --from-literal=AWS_SECRET_ACCESS_KEY=''
kubectl -n $K8S_NS create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ \
    --docker-username='aisolver' \
    --docker-password='' \
    --docker-email='integration@thingsolver.com'

# Deploy MariaDB for metastore
helm -n $K8S_NS upgrade --install metastore-db bitnami/mariadb --version 18.0.2 \
    --set auth.rootPassword=

# Deploy metastore
helm -n $K8S_NS upgrade --install solver-metastore thingsolver/solver-metastore --version 1.4.0 -f metastore.yml

# Deploy user sync job and openldap
helm -n $K8S_NS upgrade --install solver-usersync thingsolver/solver-usersync --version 1.4.0 -f ranger-sync.yml

# Deploy trino
helm -n $K8S_NS upgrade --install solver-trino thingsolver/solver-trino --version 1.4.0 -f trino.yml