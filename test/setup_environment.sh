kubeconfig=./test/kubeconfig
kubectl="kubectl --kubeconfig $kubeconfig"

meter_kube_token=$(eval ${kubectl} exec -n meter-manager $($kubectl get pod -n meter-manager --selector=mcm-app=manager --no-headers=true -o jsonpath='{.items[0].metadata.name}') -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# kube_token=$(eval ${kubectl} exec -n 6fusion-kubernetes-collector $($kubectl get pod -n 6fusion-kubernetes-collector --selector=app=mongodb --no-headers=true -o jsonpath='{.items[0].metadata.name}') -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kube_service=$(eval $kubectl get services -n default kubernetes -o jsonpath='{.spec.clusterIP}')

vars="KUBERNETES_TOKEN=${meter_kube_token}
KUBERNETES_SERVICE_HOST=${kube_service}
INFRASTRUCTURE_NAME=dev
METER_API_HOST=135.meter.dev.6fusion.com
METER_API_PORT=443
METER_API_USE_SSL=true
METER_API_TOKEN=37e4e6bc07f18e7e30c8f4dcdc78a9aefd64ae654313206159898714a8021ea3
METER_API_VERIFY_SSL=true
METER_ORGANIZATION_ID=776163-779ab4ed2605447ca28821e6fcac8871
"

for var in $vars; do
  echo "$var"
  eval "export $var"
done
