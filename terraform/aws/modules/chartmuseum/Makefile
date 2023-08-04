.PHONY: secrets
secrets:
	# make secrets env=dev|uat|prd
	@test $${env?Please pass env=dev|uat|prd argument}
	-mkdir -p sealed/$(env)/
	# (requires to have k8s context pointing to the right cluster)
	for f in $$(ls secrets/$(env)/*); do cat $$f | kubeseal --controller-name=sealed-secrets-$(env) --controller-namespace=kube-system -n chartmuseum --format yaml > sealed/$(env)/sealed-`basename $$f`; done
	for f in $$(ls sealed/$(env)/*); do cat $$f >> sealed-secrets-$(env).yaml; echo "---" >> sealed-secrets-$(env).yaml; done

