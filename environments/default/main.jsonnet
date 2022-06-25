#local k = import "github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet";
local k = import 'k.libsonnet';
local certManager = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.8/main.libsonnet';
local certificate = certManager.nogroup.v1.certificate;
local istio = import 'github.com/jsonnet-libs/istio-libsonnet/1.13/main.libsonnet';
local gateway = istio.networking.v1beta1.gateway;
local servers = gateway.spec.servers;
local port = gateway.spec.servers.port;
local tls = gateway.spec.servers.tls;
local vs = istio.networking.v1beta1.virtualService;


//local cert_manager = import "github.com/jsonnet-libs/cert-manager-libsonnet/1.8/main.libsonnet"
{
  _config:: {
     hosts: [
        "1202.com",
        "1208.com",
        "1203.com",
        "1204.com",
        "1302.com",
        "1303.com",
        "1310.com",
        "1307.com"
     ],
  },
  
  local fnCert(domainName) = certificate.new("cert-" + std.strReplace(domainName,".","-")) 
        + certificate.metadata.withNamespace("istio-system")
        + certificate.spec.withCommonName(domainName)
        + certificate.spec.withDnsNames([domainName, "www." + domainName])
        + certificate.spec.issuerRef.withKind("ClusterIssuer")
        + certificate.spec.issuerRef.withName("letsencrypt-prod")
        + certificate.spec.withSecretName("cert-" + std.strReplace(domainName,".","-")),
        
  local fnGw(domainName) = gateway.new("gw-"+ std.strReplace(domainName,".","-") )
        + {
            spec:
               {
                selector: { istio: "ingressgateway", },
                servers: [
                {
                    port: { number: 80, name: "http", protocol: "HTTP", },
                    hosts: [ domainName, "www." + domainName, ],
                    tls : { httpsRedirect: true, }
                },
                {
                    port: { number: 443, name: "https", protocol: "HTTPS", },
                    hosts: [ domainName, "www." + domainName, ],
                    tls : { mode: "SIMPLE", credentialName: "cert-" +std.strReplace(domainName,".","-"), }
                },                
                ] ,
               },
        },

  certs: [fnCert(host) for host in $._config.hosts],
  gws : [fnGw(host) for host in $._config.hosts],
  vs: vs.new("landingpage") 
     + vs.spec.withHosts([host for host in $._config.hosts] 
     + ["www." + host for host in $._config.hosts]) 
     + vs.spec.withGateways(["gw-" + std.strReplace(host,".","-") for host in $._config.hosts])
     + {
        spec: {
            http: [
            {
                match: [
                {
                    uri: { prefix: "/", },
                },
                ],
                route: [
                {
                    destination: { port: { number: 80, }, host: "landingpage", },
                },
                ],
            },
            ],
        },
        },
}
