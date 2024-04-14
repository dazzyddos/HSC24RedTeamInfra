[hosts]
%{ for ip in host_ips ~}
${ip} ansible_user=ubuntu
%{ endfor ~}