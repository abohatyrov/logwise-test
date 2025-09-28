_terraform_ops () {

  postfix=`date "+%Y:%m:%d_%H:%M:%S"`
  file_name="gcp-${environment}-${postfix}"
   
  # ---------- Variables
  gvars="_global/vars/default.tfvars"
  lvars="vars/${environment}.tfvars"
  tfstate="/Users/${USER}/.terraform.d/tfstate/${file_name}.tfstate"
  tfplan="/Users/${USER}/.terraform.d/tfplan/${file_name}.tfplan"
  
  # ---------- TERRAFORM
  terraform workspace select ${environment}
  
  case ${ops} in
    init)
      terraform init
    ;;
    plan)
      terraform plan ${target} -var-file="${gvars}" -var-file="${lvars}"
    ;;
    apply)
      terraform state pull > ${tfstate}
      terraform apply ${target} -var-file="${gvars}" -var-file="${lvars}"
    ;;
    backup)
      terraform state pull > ${tfstate}
    ;;
    import)
      terraform state pull > ${tfstate}
      terraform import ${target} -var-file="${gvars}" -var-file="${lvars}"
    ;;
    destroy)
       terraform destroy -var-file="${gvars}" -var-file="${lvars}"
    ;;
    output)
       terraform output ${target}
    ;;
    *)
      echo "Set ops !"
    ;;
  esac

}
