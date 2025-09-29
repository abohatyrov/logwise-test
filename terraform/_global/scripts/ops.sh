_terraform_ops () {
  # common files/vars
  G_VARS="_global/vars/default.tfvars"
  L_VARS="vars/${WORKSPACE}.tfvars"
  TMPDIR="${RUNNER_TEMP:-/tmp}"
  STAMP="$(date +%Y%m%d_%H%M%S)"
  TFSTATE="${TMPDIR}/gcp-${WORKSPACE}-${STAMP}.tfstate"
  TFPLAN="${TMPDIR}/gcp-${WORKSPACE}-${STAMP}.tfplan"

  # ---- always init first (non-interactive) ----
  terraform init -input=false -reconfigure

  # ---- ensure workspace exists, then select it ----
  terraform workspace select "${WORKSPACE}" >/dev/null 2>&1 || terraform workspace new "${WORKSPACE}"

  # ---- run the requested op ----
  case "${CMD}" in
    init)
      # already initialized above; do nothing extra
      ;;
    plan)
      terraform plan -input=false ${TARGET:+${TARGET}} \
        -var-file="${G_VARS}" -var-file="${L_VARS}" \
        -out="${TFPLAN}"
      ;;
    apply)
      terraform state pull > "${TFSTATE}" || true
      terraform apply -input=false ${TARGET:+${TARGET}} \
        -var-file="${G_VARS}" -var-file="${L_VARS}" \
        -auto-approve
      ;;
    destroy)
      terraform destroy -input=false \
        -var-file="${G_VARS}" -var-file="${L_VARS}"
      ;;
    backup)
      terraform state pull > "${TFSTATE}"
      ;;
    import)
      terraform state pull > "${TFSTATE}"
      terraform import ${TARGET:?provide resource address and id} \
        -var-file="${G_VARS}" -var-file="${L_VARS}"
      ;;
    output)
      terraform output ${TARGET:-}
      ;;
    *)
      echo "Unknown command '${CMD}'"
      exit 2
      ;;
  esac
}
