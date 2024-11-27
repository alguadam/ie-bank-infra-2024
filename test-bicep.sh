#!/bin/bash

RESOURCE_GROUP=BCSAI2024-DEVOPS-STUDENTS-B-DEV
LOCATION="East US"

az login
az account set --subscription e0b9cada-61bc-4b5a-bd7a-52c606726b3b

az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Validating Bicep file: ./main.bicep"
az bicep build --file ./main.bicep

# echo "Simulating deployment to test resource group"
# az deployment group create --resource-group $RESOURCE_GROUP --template-file ./main.bicep --confirm-with-parameter


echo "Bicep file validation completed."
