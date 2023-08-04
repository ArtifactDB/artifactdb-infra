#!/bin/bash
# Set default kubectl version
KUBECTL_VERSION=${KUBECTL_VERSION:-"v1.25.0"}

# Check if Homebrew is installed on macOS and install if not
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

# Install Terraform
echo "Installing Terraform..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    sudo apt-get update && sudo apt-get install terraform
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
fi

# Install AWS CLI
echo "Installing AWS CLI..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    brew install awscli
fi

# Install Helm
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install jq
echo "Installing jq..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sudo apt-get install jq
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    brew install jq
fi

echo "All done. Please configure AWS CLI by running 'aws configure'."
