# VIRTUAL MACHINE PLACEMENT IN AZURE

# OPTION 1: DEPLOY VM IN PROXIMITY PLACEMENT GROUP

# Define Variables 
$Location = "UAE North"
$PPGName = "Proximity-Placement-Group-01"
$VMName = "ppgVM"
$VMSize = "Standard_D2s_v3"
$VNetName = "ppgVNet"
$SubnetName = "ppgSubnet"
$NICName = "ppgNIC"
$NSGName = "ppgNSG"
$VNetAddressPrefix = "10.0.0.0/16"
$SubnetAddressPrefix = "10.0.1.0/24"

# Create VM Login Credentials 
$VMLocalAdminUser = "AdminUserName"
$VMLocalAdminSecurePassword = ConvertTo-SecureString -String "AdminPassword" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)

# Select the Resource Group to deploy the VM 
$ResourceGroup = Get-AzResourceGroup | Select-Object -First 1

# Select the VNet, Subnet and NSG. First check that they exist. If not, create them. 
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $VNetName `
 -ErrorAction SilentlyContinue
if (-not $VNet) {
    Write-Host "Creating Virtual Network..."
    $VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $VNetName `
     -Location $Location -AddressPrefix $VNetAddressPrefix
}

$Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName -ErrorAction SilentlyContinue
if (-not $Subnet) {
    Write-Host "Creating Subnet..."
    $VNet | Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix | Set-AzVirtualNetwork
    $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName
}

$NSG = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $NSGName `
 -ErrorAction SilentlyContinue
if (-not $NSG) {
    Write-Host "Creating Network Security Group..."
    $NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location `
     -Name $NSGName
}

# Check that the NIC exists. If not, create NIC
$NIC = Get-AzNetworkInterface -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $NICName `
 -ErrorAction SilentlyContinue
if (-not $NIC) {
    Write-Host "NIC not found. Creating a new one..."    
    $NIC = New-AzNetworkInterface -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $NICName `
        -Location $Location -SubnetId $Subnet.Id -NetworkSecurityGroupId $NSG.Id
}

Write-Host "Using NIC: $($NIC.Name)"

# Create the Proximity Placement Group where the VMs will be deployed
$PPG = New-AzProximityPlacementGroup -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $PPGName `
 -Location $Location -ProximityPlacementGroupType Standard

# Define the VM Configuration 
$VMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize -ProximityPlacementGroup $PPG.Id |
    Set-AzVMOperatingSystem -Linux -ComputerName $VMName -Credential $Credential |
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "22_04-lts" -Version "latest" |
    Add-AzVMNetworkInterface -Id $NIC.Id

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -VM $VMConfig


# .............................................................................................................

# OPTION 2: DEPLOY VM IN AN AVAILABILITY SET

# Define Variable
$AvailabilitySetName = "Availability-Set-01"

# Create Availability Set
$AvailabilitySet = New-AzAvailabilitySet -ResourceGroupName $ResourceGroup.ResourceGroupName `
 -Name $AvailabilitySetName -Location $Location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 5 `
 -Sku Aligned

# Define the VM Configuration 
$VMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvailabilitySet.Id |
    Set-AzVMOperatingSystem -Linux -ComputerName $VMName -Credential $Credential |
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "22_04-lts" -Version "latest" |
    Add-AzVMNetworkInterface -Id $NIC.Id

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -VM $VMConfig


#............................................................................................................

# OPTION 3: CREATE VIRTUAL MACHINE SCALE SET

# Define Variables
$InstanceCount = 2 
$VMssName = "Virtual-Machine-Scale-Set-01"
$VMssNICConfigName = "VMssNICConfig"
$IPConfigName = "VMssIPConfig"

# Attach NSG to Subnet
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName -AddressPrefix $SubnetAddressPrefix `
 -NetworkSecurityGroup $NSG | Set-AzVirtualNetwork

# Create Scale Set Configuration
$VMssConfig = New-AzVmssConfig -Location $Location -SkuCapacity $InstanceCount -SkuName $VMSize -UpgradePolicyMode Automatic | 
    Set-AzVmssOsProfile -ComputerNamePrefix "vmss" -AdminUsername $VMLocalAdminUser -AdminPassword $VMLocalAdminSecurePassword |
    Set-AzVmssSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "22_04-lts" -Version "latest"

# Set VMSS Network Configuration
$IPConfig = New-AzVmssIpConfig -Name $IPConfigName -SubnetId $Subnet.Id
$NICConfig = Add-AzVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $VMssConfig `
 -Name $VMssNICConfigName -Primary $true -IPConfiguration $IPConfig

# Create the Scale Set
Write-Host "Deploying VM Scale Set..."
New-AzVmss -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $VMssName -VirtualMachineScaleSet $VMssConfig