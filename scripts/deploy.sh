 #!/bin/bash 
echo "All Networks supplied: $@"
chain_array=($@)
for i in "${chain_array[@]}"
do
   echo "Deploying to $i Network"
   npx hardhat run scripts/deploy.js --network $i
   echo "Deployed to: $i Network"
done
