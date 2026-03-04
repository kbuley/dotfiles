function update_kubeconfigs() {
  [ ! -d "$HOME/.kube/config.d" ] && mkdir $HOME/.kube/config.d -p -v
  # Will run only if there are new files in the config directory
  local new_files=$(find $HOME/.kube/config.d/ -newer $HOME/.kube/config -type f | wc -l)
  if [[ $new_files -ne "0" ]]; then
    local current_context=$(kubectl config current-context) # Save last context
    local kubeconfigfile="$HOME/.kube/config"               # New config file
    cp -a $kubeconfigfile "${kubeconfigfile}_$(date +"%Y%m%d%H%M%S")"  # Backup
    local kubeconfig_files="$kubeconfigfile:$(ls $HOME/.kube/config.d/* | tr '\n' ':')"
    KUBECONFIG=$kubeconfig_files kubectl config view --merge --flatten > "$HOME/.kube/tmp"
    mv "$HOME/.kube/tmp" $kubeconfigfile && chmod 600 $kubeconfigfile
    export KUBECONFIG=$kubeconfigfile
    kubectl config use-context $current_context --namespace=default
  fi
}

