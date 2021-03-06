FROM fedora:latest
#FROM registry.access.redhat.com/ubi8-init
USER root

LABEL maintainer="abeekhof@redhat.com"

RUN dnf search kubernetes
RUN dnf install -y pcs which passwd findutils bind-utils kubernetes-client gettext fence-agents-virsh fence-virt fence-agents-redfish iputils initscripts chkconfig nmap openssh-clients && rm -rf /var/cache/yum

RUN mkdir -p /etc/systemd/system-preset/
RUN echo 'enable pcsd.service' > /etc/systemd/system-preset/00-pcsd.preset
RUN systemctl enable pcsd

#RUN dnf install -y lsof && rm -rf /var/cache/yum

#LABEL RUN /usr/bin/docker run -d \$OPT1 --privileged --net=host -p 2224:2224 -v /sys/fs/cgroup:/sys/fs/cgroup -v /etc/localtime:/etc/localtime:ro -v /run/docker.sock:/run/docker.sock -v /usr/bin/docker:/usr/bin/docker:ro --name \$NAME \$IMAGE \$OPT2 \$OPT3

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/high_availability_add-on_reference/s1-firewalls-haar
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_high_availability_clusters/assembly_creating-high-availability-cluster-configuring-and-managing-high-availability-clusters
EXPOSE 2224/tcp
EXPOSE 5404/udp
EXPOSE 5405/udp
EXPOSE 5406/udp
EXPOSE 5407/udp
EXPOSE 5408/udp
EXPOSE 5409/udp
EXPOSE 5410/udp
EXPOSE 5411/udp
EXPOSE 5412/udp

ADD *.sh *.in /root/
ADD k8sDeployment /usr/lib/ocf/resource.d/pacemaker

CMD ["/usr/lib/systemd/systemd", "--system"]
#ENTRYPOINT /root/loop.sh