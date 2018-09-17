instance_type="t2.micro"
cidr_blocks={
    vpc="190.160.128.0/17"
    subnet="190.160.129.0/24"
    }
Devops_AMIS= {
     git = "ami-b374d5a5"
    jenkinMaster = "ami-4b32be2b"
}
instance_types = {
    git="t2.micro"
}
name="demo"
layer=["demo","demo1"]
AppNames={
    git="gitName"
}
env="DevPOC"
name="POC"
poc_from_port="0"
poc_to_port="0"