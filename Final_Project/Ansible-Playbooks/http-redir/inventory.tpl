[http_redir]
%{ for ip in httpredir_private_ip ~}
${ip} ansible_user=ubuntu
%{ endfor ~}