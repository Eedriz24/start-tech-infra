# #!/usr/bin/env bash
# set -e

# cd terraform

# echo "=== Confirming current state (should show ONLY the data source right now) ==="
# terraform state list | grep module.networking || true
# echo ""

# echo "=== STEP 1: Subnets FIRST — this fixes the count-evaluation error for good ==="
# # NOTE: subnets alone still won't fully satisfy count, since aws_subnet.public
# # etc. resources reference the VPC. But subnet import itself doesn't require
# # the VPC to already be in state (AWS side is unaffected by TF state), so this
# # order works: subnets, then VPC, then everything downstream of VPC.

# terraform import module.networking.aws_subnet.public[0] subnet-009a8bb7fc12dc6a8
# terraform import module.networking.aws_subnet.public[1] subnet-03642f5fa4075a89a
# terraform import module.networking.aws_subnet.private[0] subnet-0878c991055735067
# terraform import module.networking.aws_subnet.private[1] subnet-0e6dbb85855bf5f4e
# terraform import module.networking.aws_subnet.database[0] subnet-003b20fb159b0b39c
# terraform import module.networking.aws_subnet.database[1] subnet-047bde93bc1daee84

# echo "=== STEP 2: VPC ==="

# terraform import module.networking.aws_vpc.starttech-vpc vpc-041850a0527e1108f

# echo "=== STEP 3: IGW, EIP, NAT Gateway ==="

# terraform import module.networking.aws_internet_gateway.this igw-050dfe7b70c5ac5d6
# terraform import module.networking.aws_eip.nat eipalloc-06a049a4a6120382a
# terraform import module.networking.aws_nat_gateway.this nat-019310afa08d9b618

# echo "=== STEP 4: Route tables ==="

# terraform import module.networking.aws_route_table.public rtb-073cdb87e225adb4f
# terraform import module.networking.aws_route_table.private rtb-0f542111ccf202358

# echo "=== STEP 5: Route table associations (public + database — real ones exist in AWS) ==="

# terraform import module.networking.aws_route_table_association.public[0] rtbassoc-041141047722c537c
# terraform import module.networking.aws_route_table_association.public[1] rtbassoc-0c603ddfc97f12195
# terraform import module.networking.aws_route_table_association.database[0] rtbassoc-0c0397b8570b937d6
# terraform import module.networking.aws_route_table_association.database[1] rtbassoc-01728272003c98661

# echo ""
# echo "=== NOTE: private[0]/private[1] route table associations are intentionally NOT imported ==="
# echo "They don't exist in AWS. Terraform will CREATE them fresh on the next apply —"
# echo "this also fixes the missing NAT route for your private subnets."
# echo ""

# echo "=== STEP 6: Verify — should list all 16 networking resources now ==="
# terraform state list | grep module.networking

# echo ""
# echo "Done. Now run a clean targeted 'terraform plan' and paste the FULL output before applying."