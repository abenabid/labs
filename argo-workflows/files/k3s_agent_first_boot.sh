#!/bin/bash
sudo hostnamectl set-hostname ${hostname}
curl -sfL https://get.k3s.io | sh -s - agent --server https://${k3s_server}:6443 --token 12345