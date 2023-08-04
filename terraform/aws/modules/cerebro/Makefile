.PHONY: secrets
secrets:
	# make secrets env=dev|uat|prd
	# (requires to have k8s context pointing to the right cluster)
	for f in $$(ls secrets/$(env)/*.yaml); do cat $$f | kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system -n cerebro --format yaml > sealed/$(env)/sealed-`basename $$f`; done
	sed -s '$$a---' sealed/$(env)/*.yaml > sealed/$(env)/sealed-secrets-$(env).yaml

