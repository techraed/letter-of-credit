module.exports = {
  networks: {
    development: {
        host: "127.0.0.1",
        port: 8545,
        network_id: "5777" // Match any network id
    },

    // geth --rinkeby --rpc console --port 30304 --rpcport 8544 --wsport 8548 --syncmode=fast --cache=1024 --bootnodes=enode://a24ac7c5484ef4ed0c5eb2d36620ba4e4aa13b8c84684e1b4aab0cebea2ae45cb4d375b77eab56516d34bfbd3c1a833fc51296ff084b770b94fb9028c4d25ccf@52.169.42.101:30303
    rinkeby: {  // testnet
        host: "localhost",
        port: 8544,
        network_id: 4
    },

    // geth --rpcport 8549 --wsport 8550 --rpc console --fast
    mainnet: {
        host: "localhost",
        port: 8549,
        network_id: 1,
        gasPrice: 7000000000
    }
  }
};