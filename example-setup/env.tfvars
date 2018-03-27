# This parameter file is configured to be used with a 30 Core / 120 GB RAM quota provided by SysEleven GmbH.

public_network = "ext-net"

image = "Ubuntu 16.04 LTS sys11 optimized 2018.03.21"

# Used resources can be configures with the following parameters
number_appservers = "4"

number_dbservers = "3"

number_servicehosts = "1"

flavor_lb = "m1.tiny"

flavor_appserver = "m1.tiny"

flavor_dbserver = "m1.tiny"

flavor_servicehost = "m1.tiny"

consul_mastertoken_length = "30"

consul_agenttoken_length = "30"

# Please exchange the ssh public keys below with yours 
ssh_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzBd/ZXus0RGHqi6TdfLQcZML4b+woARlbV/+V9bsvdXKbe7FVLhd2oYV5n5kBI4DfEtD0J5BXBXbzG1BW9WmB/Ty2wlwUu+NFDCn+3kDTGov9Wlo5bfkPD/KDi/UNOqJvOMoCGzkCK04Di0ykG38gLKeOUDtLbh/s9Manr9vDguvtBV4UE7/kNQFzGFffB3ZyvKVzikrsm5Ri3knjCRwppN6BGZVMowTmhDgczyS3CJekdCBrgXu3eePuWbFnPVmSAapl775ouCLGAW0KsiSc9T4iTdpAMFxtvA5Pbciv4FDOfEf8w1t5xgko3KAPMLz37b7mqmRhQTwkW3BNaiZqLTC2RqZkHI5a6u655I1SJYZbJT2F/Ys8WaKTSdGLxRJ+rcV8YV0FveP6fa97gpqp6UmstGE7QsRaXPc9OG3U0hCTPYFlJ9QJ95FQMGQMt3/qsZHGWSI3H8jLn8Pqeky+XZA0Xq7cJq9n5gGpMVH2UgRT1WzbCAYiDMiNtzIxBXg5xVCzkhN98S7p+IxOpw6BsByOrIogo5lyC/qVS6tD5XCsAtOFk0ldhB/FuuyOrR1pSq3GZCyuiXkXWrwuSw7k5a7pkh3+E+t2pqYWgLFAaClNA0TI4UFfNnkgEfozop5UWuvNkbd98ruBHaGrQ0ASqWk4nEztHxUeJ/NkQ+n5uw==",
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDN7WgiiXGQju8PlZ2IVoQygxeLzxvt2baZx9Q1JmfHed6Pxz+yiibbWiZIMDYiu76FSf6SENoUdSb56jcuFv4CCfu1lnLa3p/si/ic7BlDeIs6754cqdQTMlHShPw9z69cJKdd0qsA5KPBL7tEzCUWrRDidsiHza9cj/mlZ7w5X6+BUhXYa/0UK6cjkYD/T7qHhgYAGCalhwRIIPdoFhllkGaoO5r0gUgvkv1PFpK7psNfuxbuA4th0gU4Qhgj8hTpmcRFceneIwG9ZpEIbhbfyQcA3pPSZFDGsdcnDhHMHXHZsjGLca1lXDh7izn3t8fHLXAjwMnw5OdsNu6vARk+JZsZprrwSi++WWd43KUeGNdr5KLgHQDaNiLhgBKwZk+4ZpK1BAl4PZidX6P+idu4qWHNEv49yzxfI+puPbwhNBtWIrehZVKSah9/ALYtDyYBtMRyF9i9fW4O17Ov5dR10vrq4Mm6NlBJynCFjMY6z8hZFZCHc3QnPLCwfIeRH2PRMJonF5+wsyc4kxCwqK1HLsvwSFcAVdsEtFeppEEq5/WjDiv6sb62h+lckL/hXm+Y3rKULpEoHuVl/BX/rwCI1c6ES6asLQ3ZkEYo/0s3FnzZlu2qEYERddUAmzunAPx3fzcMjNUsEmpZS1uXUOFIenL+rj1kSmDfb90fQQRnnQ==",
]
