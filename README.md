# PoC: kicbase build job — $GITHUB_ENV persistence defeats the "PR-code steps do not get the token" control

Replica of `kubernetes/minikube/.github/workflows/kicbase.yml` `build-kicbase` job.
The `pr` branch modifies only `hack/build_auto_pause.sh` and `Makefile`, which the
`Prepare build metadata` step executes. Test only.
