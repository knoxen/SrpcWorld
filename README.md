## SrpcWorld

#### A Secure Remote Password Cryptor Demo for Elixir

The Secure Remote Password Cryptor (SRPC) is a security framework based on the [Secure Remote Password](http://srp.stanford.edu/) (SRP) protocol. SRPC builds on SRP to provide application-layer security for client/server communications. This provides a single entity trust model (no trusted third party) with mutual authentication and a host of other features. SRPC is transport independent. This demo uses HTTP.

The primary purpose of this demo is to show the touch points for Elixir application integration of the SRPC framework. Secondarily, the demo can be configured to use a client-side proxy to examine the structure of the SRPC messaging packets.

The `SrpcWorld` demo consists of the following server and client applications:

  - `SrpcWorld.Server` provides implementation for the following routes

     - Simple HTTP requests
        - `/hello` &ndash; says hello to the `name` specified in a URL request query string
        - `/reverse` &ndash; reverses data provided in a URL request
     - HTTP JSON API
        - `/status` &ndash; on/off status of a set of lights
        - `/action` &ndash; control the on/off state of the lights

  - `SrpcWorld.Client` provides a simple API to access `SrpcWorld.Server` simple HTTP requests
  - `SrpcWorld.Lights` provides a simple API to access `SrpcWorld.Server` HTTP JSON API

SRPC framework functionality is added through `SrpcPlug` on the server side and `SrpcClient` on the client side.

### <a name="TOC"></a>Table of Contents
  - [Install Elixir](#Install)
  - [Compile SrpcWorld](#Compile)
  - [Start SrpcWorld](#Start)
  - [Run SrpcWorld](#Run)
  - [Inspect Traffic](#Inspect)
  - [Client/Server Configuration](#Configure)
  - [Under the Hood](#UnderTheHood)
    - [Lib Connection](#LibConnection)
    - [User Registration](#UserRegistration)
    - [User Connection](#UserConnection)
    - [Key Refresh](#KeyRefresh)
    - [Reconnect](#Reconnect)
  - [Fin](#Fin)

### <a name="Install"></a>Install Elixir

The Elixir language organization has detailed information regarding the [installation of Elixir](https://elixir-lang.org/install.html).

<div style="text-align: right">[Table of Contents](#TOC)</div>

### <a name="Compile"></a>Compile SrpcWorld

In each of the client and server directories,

```bash
mix deps.get
mix compile
```

<div style="text-align: right">[Table of Contents](#TOC)</div>

### <a name="Start"></a>Start SrpcWorld

In the `server` directory:

<pre><code class="bash">> iex -S mix
&hellip;
<strong>server &there4;</strong>
</code></pre>

In the `client` directory:

<pre><code class="bash">> iex -S mix
&hellip;
<strong>client &there4;</strong>
</code></pre>

Each directory contains an `.iex.exs` file that sets the IEx prompt to either client or server, followed by a &there4; sign.

<div style="text-align: right">[Table of Contents](#TOC)</div>

### <a name="Run"></a>Run SrpcWorld

##### HTTP calls

`SrpcWorld.Client` provides an API to access `SrpcWorld.Server`. For example, `SrpcWorld.Client.say_hello/1` sends an HTTP GET `/hello` request to the server. However, we want this communication to be secure, so `SrpcWorld.Client` actually uses the SRPC framework to make the call. First, let's say hello to "Elixir" in the client IEx shell.

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Client.say_hello("Elixir")
10:02:21.703 [info]  Connected to http://localhost:8082
"Aloha Elixir"
</code></pre>

The `SrpcWorld.Server` is apparently vacationing in Hawai&#8216;i as we see the __*say_hello*__ response is _Aloha Elixir_.

The info log message received before the __*say_hello*__ response informs us that the client connected to the `SrpcWorld.Server` at the specified URL. Whenever the `SrpcWorld.Client` makes a call, it reuses an SRPC connection maintained in its `GenServer` state. Since there was no existing connection, one was created in `SrpcWorld.Client` with the call:

```elixir
  {:ok, conn} = SrpcClient.connect()
```

`SrpcClient.connect/0` returns a `SrpcClient.Connection` that is used to send secure messages to the `SrpcWorld.Server`. The connection is passed as the first parameter to `SrpcClient` functions such as in the implementation of `SrpcWorld.Client.say_hello/1`:

```elixir
  conn
  |> SrpcClient.get("/hello?name=#{name}")
```

Subsequent `SrpcWorld.Client` calls reuse the same `SrpcClient.Connection`:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Client.reverse("Stressed was I ere I saw desserts")
"stressed was I ere I saw dessertS"
</code></pre>

##### Controlling lights

`SrpcWorld.Server` fronts a set of virtual lights that can be controlled using the client-side `SrpcWorld.Lights` module. Controlling the lights requires a valid user login. The demo server includes setup of user __*srpc*__ with password __*secret*__. To login, we use `SrpcWorld.Lights.login/2`:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Lights.login("srpc", "secret")
:ok
</code></pre>

If you've configured a proxy to observe SRPC traffic you'll see that no information regarding the user ID or password is visible (or leaks) during either SRPC registration or login messaging. In fact, the user password *never leaves the client*. The [Under the Hood](#UnderTheHood) section describes what data is actually used to authenticate a user.

Let's get the status of the lights:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Lights.status()
%{"green" => "off", "red" => "off", "yellow" => "off"}
</code></pre>

All the lights are off. Let's turn the **red** light on:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Lights.on("red")
%{"green" => "off", "red" => "on", "yellow" => "off"}
</code></pre>

Now let's turn the **green** light on:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Lights.on("green")
%{"green" => "on", "red" => "on", "yellow" => "off"}
</code></pre>

Note the **red** light stayed on. We could use `SrpcWorld.Lights.off/1` to turn the **red** light off, or we could use `SrpcWorld.Lights.switch/1` which switches to a particular light and turns all others off:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcWorld.Lights.switch("yellow")
%{"green" => "off", "red" => "off", "yellow" => "on"}
</code></pre>

In each of the above calls, `SrpcWorld.Lights` is sending HTTP JSON API requests to `SrpcWorld.Server` using `SrpcClient.post/2`. All the calls are secured via the SRPC framework.

<div style="text-align: right">[Table of Contents](#TOC)</div>

### <a name="Inspect"></a>Inspect Traffic

The demo can be configured to use a proxy to inspect the traffic between the `SrpcWorld.Client` and `SrpcWorld.Server`. Using such a proxy will reveal that all SRPC calls "look" identical. Each call is an HTTP POST to the URL __*http://host:port/*__ (where the `host` and `port` are specified in the configuration files). Neither the request nor response headers contain any meaningful demo application information. And the request and response bodies are encrypted. The bodies of an example request (top) and response (bottom) looks like:

![](images/ReqRespPair.png)

<div style="text-align: right">[Table of Contents](#TOC)</div>

#### <a name="Configure"></a>Configure SrpcWorld

Most of the demo configuration should not be changed. However, values of interest that can be changed on the server are `host` and `port` and on the client are `port` and an optional `proxy` setting.

##### SrpcWorld.Server

Server-side settings are in __*server/config/config.exs*__.

<a name="ServerConfig"></a>
###### :srpc_plug

Server-side SRPC framework functionality is provided by the `SrpcPlug` module. `SrpcPlug` shares a pre-defined relationship with the `SrpcClient` module used by `SrpcWorld.Client`. The server portion of this pre-defined relationship is contained in the `server/priv/server.srpc` file and should not be altered. The SRPC framework also requires a module that provides the `SrpcHandler` behaviour (to maintain server-side state for the SRPC framework).

```elixir
config :srpc_plug,
  srpc_file: "priv/server.srpc",
  srpc_handler: SrpcWorld.Server.SrpcHandler
```

`SrpcPlug` is compiled with a time-limited demo of the SRPC framework that is valid for just over 3 hours after server startup. If the `SrpcWorld.Server` attempts to process a message through `SrpcPlug` after running for more than this time limit the plug will return a custom Fahrenheit 451 status code. Per the `Plug` documentation, this custom code status must be specified in the server configuration as follows:

```elixir
config :plug, :statuses, %{
  451 => "Srpc Demo Expired"
}
```

The `SrpcWorld` demo uses `Cowboy` for its HTTP server.

###### :cowboy
```elixir
config :cowboy,
  cowboy_opts: [
    port: 8082,
    acceptors: 5
  ]
```

The `SrpcWorld.Server.SrpcHandler` module uses `kncache` (a simple cache) for maintaining server-side data. These settings configure the necessary caches and default TTLs.

###### :kncache
```elixir
config :kncache,
  caches: [
    srpc_exch: 30,
    srpc_nonce: 35,
    srpc_conn: 3600,
    srpc_reg: 3600,
    user_data: 3600
  ]
```

##### SrpcWorld

Client-side settings are in __*client/config/config.exs*__.

Client-side SRPC framework functionality is provided by the `SrpcClient` module. `SrpcClient` shares a pre-defined relationship with the `SrpcPlug` module used by `SrpcWorld.Server`. The client portion of this pre-defined relationship is contained in the `client/priv/client.srpc` file and should not be altered.

SRPC is transport independent. This demo uses `SrpcPoison`, which provide HTTP transport via [HTTPoison](https://github.com/edgurgel/httpoison).

<a name="ClientConfig"></a>
###### :srpc_client
```elixir
config :srpc_client,
  srpc_file: "priv/client.srpc",
  transport: SrpcPoison
```

`SrpcWorld` clients connect to the `SrpcWorld.Server` on a specified `host` and `port`.

```elixir
config :srpc_client, :server,
  host: "localhost",
  port: 8082
```

###### :srpc_poison

An optional `proxy` configuration allows  HTTP traffic to be channeled through a proxy for inspection purposes. This setting is passed to `HTTPoison` as a request option. See [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html#request/5) for further information. Setting the `proxy` configuration would look like:

```elixir
config :srpc_poison, proxy: "http://localhost.charlesproxy.com:8888"
```

<div style="text-align: right">[Table of Contents](#TOC)</div>

### <a name="UnderTheHood"></a>Under the Hood

Both `SrpcWorld.Client` and `SrpcWorld.Lights` use an `SrpcClient.Connection` to communicate securely with `SrpcWorld.Server`. `SrpcWorld.Client` does not require a valid user login but still ensures mutual authentication between the `SrpcClient` being used by `SrpcWorld.Client` and the `SrpcPlug` being used by `SrpcWorld.Server`. This mutual authentication is achieved using values in the files specified by the `:srpc_file` configuration of the [client](#ClientConfig) and [server](#ServerConfig). These values form the [SRP](http://srp.stanford.edu/design.html) pre-defined relationship between the SRPC client and server processes.

<div style="text-align: right">[Table of Contents](#TOC)</div>

##### <a name="LibConnection"></a>SRPC Lib Connection

Let's take a peek under the hood by creating an `SrpcClient.Connection`. It would be best to [restart](#Start) both the client and server applications to clean out any residue from earlier demo activity. The client and server IEx sessions can each be terminated by using Cntl-C twice.

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.connect()
{:ok, #PID<0.226.0>}
</code></pre>

`SrpcClient.connect/0` returns `{:ok, conn_pid}` for a successful connection attempt. We created a connection, but didn't grab it. Let's fix that:

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, conn} = SrpcClient.connect()
{:ok, #PID<0.226.0>}
</code></pre>

Because the `SrpcClient.connect/0` call does not specify user credentials, the connection returned is an SRPC __*lib connection*__ (i.e., a connection that has mutually authenticated the SRPC libraries in use). We can get information regarding the connection using `SrpcClient.info/1`:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.info(conn)
%SrpcClient.Conn.Info{
  accessed: 12,
  count: 0,
  created: 12,
  keyed: 12,
  name: :LibConnection_2
}
</code></pre>

The info reports how long ago (in seconds) the connection was created, accessed, and keyed, as well as the connection name and a count of the number of time used. Note the `conn` reference actually holds the second connection created since we didn't capture the first.

We can use the connection by sending it to various `SrpcClient` calls. For example, to POST a request to reverse the string `string`:

<pre><code class="elixir"><strong>client &there4;</strong> conn |> SrpcClient.post("/reverse", "string")
{{:ok, "gnirts"}, #PID<0.228.0>}
</code></pre>

Inspecting the info again, we'll see the connection has been updated:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.info(conn)
%SrpcClient.Conn.Info{
  accessed: 11,
  count: 1,
  created: 32,
  keyed: 32,
  name: :LibCon
</code></pre>

Let's close the connection and get a new one:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.close(conn)
:ok

<strong>client &there4;</strong> {:ok, conn} = SrpcClient.connect()
{:ok, #PID<0.304.0>}

<strong>client &there4;</strong> SrpcClient.info(conn)
%SrpcClient.Conn.Info{
  accessed: 11,
  count: 0,
  created: 11,
  keyed: 11,
  name: :LibConnection_3
}

<strong>client &there4;</strong> :observer.start
</code></pre>

The `SrpcClient` application structure at this point looks like:

![](images/SrpcClient-observer.png)

There are two connections. `LibConnection_3` is referenced by our current `conn`, whereas `LibConnetion_1` is the first connection we didn't capture. Let's clean up a bit and close that dangling connection. `SrpcClient.connections/0` returns a list of `{atom, pid}` pairs which we can use to close `LibConnection_1`:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.connections() |> Keyword.get(:LibConnection_1) |> SrpcClient.close()
:ok
</code></pre>

We can get detailed information regarding a connection using `SrpcClient.info/2`:

<pre><code class="elixir"><strong>client &there4;</strong> conn |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460526,
  conn_id: "nPF4MDLrMp8PjNBpb6tBhQfjd6",
  created: -576460526,
  crypt_count: 0,
  entity_id: "srpc_demo_Gc6kmLMM",
  keyed: -576460526,
  name: :LibConnection_3,
  pid: #PID<0.304.0>,
  reconnect: nil,
  req_mac_key: <<212, 250, 216, 31, 26, 224, 23, 3, 154, 87, 90, 226, 33, 113,
    192, 47, 35, 46, 90, 242, 111, 96, 133, 149, 27, 172, 76, 134, 150, 213,
    148, 185>>,
  req_sym_key: <<159, 105, 54, 5, 199, 44, 118, 103, 123, 129, 227, 232, 78, 30,
    38, 17, 138, 20, 238, 218, 180, 173, 27, 56, 112, 150, 202, 170, 183, 79,
    160, 156>>,
  resp_mac_key: <<2, 78, 228, 4, 64, 6, 184, 181, 253, 145, 255, 10, 204, 12,
    200, 146, 6, 16, 35, 176, 65, 3, 240, 71, 172, 193, 252, 79, 155, 138, 91,
    82>>,
  resp_sym_key: <<222, 238, 153, 33, 128, 84, 126, 48, 242, 3, 162, 70, 253, 67,
    11, 9, 164, 118, 204, 250, 210, 149, 215, 94, 138, 33, 235, 68, 1, 247, 182,
    164>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :lib,
  url: "http://localhost:8082"
}
</code></pre>

The information includes four binary keys. The `*_sym_key`s are used for encryption (confidentiality) and the `*_mac_key`s are used for message authentication codes (data integrity and origin). Distinct keys are used in each direction of messaging.

Let's see how this connection info is handled on the server side. For the `SrpcWorld` demo, server-side SRPC processing is handled by the `SrpcPlug` module. There is an `:srpc_srv` module (written in Erlang) but it is a library, not an application, and hence has no state. It is up to the server-side application to provide necessary SRPC state management via a module providing the `:srpc_handler` behaviour. In the `SrpcWorld` demo, the configured [SRPC handler](#ServerConfig) is `SrpcWorld.Server.SrpcHandler`.

To view the server-side information for the `LibConnection_3` connection, switch over to the server IEx shell and use the `conn_id` from the `SrpcClient.info/2` listing above:

<pre><code class="elixir"><strong>server &there4;</strong> SrpcWorld.Server.SrpcHandler.get_conn("nPF4MDLrMp8PjNBpb6tBhQfjd6")
{:ok,
 %{
   conn_id: "nPF4MDLrMp8PjNBpb6tBhQfjd6",
   entity_id: "srpc_demo_Gc6kmLMM",
   req_mac_key: <<212, 250, 216, 31, 26, 224, 23, 3, 154, 87, 90, 226, 33, 113,
     192, 47, 35, 46, 90, 242, 111, 96, 133, 149, 27, 172, 76, 134, 150, 213,
     148, 185>>,
   req_sym_key: <<159, 105, 54, 5, 199, 44, 118, 103, 123, 129, 227, 232, 78,
     30, 38, 17, 138, 20, 238, 218, 180, 173, 27, 56, 112, 150, 202, 170, 183,
     79, 160, 156>>,
   resp_mac_key: <<2, 78, 228, 4, 64, 6, 184, 181, 253, 145, 255, 10, 204, 12,
     200, 146, 6, 16, 35, 176, 65, 3, 240, 71, 172, 193, 252, 79, 155, 138, 91,
     82>>,
   resp_sym_key: <<222, 238, 153, 33, 128, 84, 126, 48, 242, 3, 162, 70, 253,
     67, 11, 9, 164, 118, 204, 250, 210, 149, 215, 94, 138, 33, 235, 68, 1, 247,
     182, 164>>,
   sha_alg: :sha256,
   sym_alg: :aes256,
   type: :lib
 }}
</code></pre>

 Note the `conn_id`, `entity_id`, `type` and cryptographic keys are identical on each side of the connection.

<div style="text-align: right">[Table of Contents](#TOC)</div>

##### <a name="UserRegistration"></a>SRPC User Registration

On the client, let's register a new user:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.register("chigurh", "call it")
:ok
</code></pre>

and then look at what information is received and maintained by the server:

<pre><code class="elixir"><strong>server &there4;</strong> SrpcWorld.Server.SrpcHandler.get_registration("chigurh")
{:ok,
 %{
   kdf_salt: <<111, 86, 19, 83, 159, 172, 246, 136, 209, 166, 225, 167>>,
   srp_salt: <<145, 111, 37, 210, 141, 70, 10, 110, 205, 40, 104, 204, 30, 230,
     104, 151, 194, 218, 247, 149>>,
   user_id: "chigurh",
   verifier: <<126, 98, 148, 155, 243, 98, 176, 154, 54, 24, 181, 75, 200, 123,
     241, 114, 37, 93, 85, 54, 198, 144, 124, 231, 222, 244, 96, 110, 208, 251,
     130, 175, 190, 96, 140, 27, 131, 251, 27, 95, 241, 178, 238, 154, 143, 94,
     136, 223, 241, 206, 214, 3, 44, 127, 246, 179, 93, 48, 202, 243, 211, 13,
     197, 193, 134, 180, 171, 75, 55, 142, 31, 40, 85, 191, 204, 142, 127, 61,
     163, 239, 219, 38, 193, 119, 216, 223, 8, 168, 238, 3, 167, 57, 225, 111,
     143, 64, 115, 208, 183, 245, 110, 148, 244, 145, 77, 181, 158, 13, 180, 60,
     3, 204, 21, 14, 51, 69, 139, 165, 236, 178, 78, 82, 149, 159, 199, 106,
     190, 128, 198, 187, 204, 154, 15, 94, 55, 74, 112, 48, 162, 153, 127, 154,
     245, 93, 13, 244, 103, 237, 107, 96, 164, 24, 100, 117, 138, 110, 134, 245,
     175, 207, 27, 23, 243, 78, 9, 121, 109, 220, 15, 9, 42, 233, 48, 242, 155,
     126, 119, 238, 217, 13, 32, 159, 181, 0, 44, 96, 13, 164, 172, 131, 241,
     155, 185, 5, 93, 33, 230, 117, 2, 14, 46, 43, 62, 124, 216, 18, 250, 199,
     194, 196, 95, 27, 31, 222, 208, 117, 243, 238, 66, 59, 112, 240, 179, 199,
     205, 28, 60, 15, 227, 35, 102, 72, 12, 110, 185, 11, 114, 214, 246, 48, 78,
     154, 85, 154, 29, 15, 46, 148, 241, 254, 101, 182, 84, 52, 71, 250>>
 }}
</code></pre>

`SrpcClient.register/2` creates random `kdf_salt` and `srp_salt` values. `kdf_salt` is used for PDKDF2 key stretching of the user's password, whereas `srp_salt` is used to create the user's [SRP](http://srp.stanford.edu/design.html) private key from the stretched password. The private key is then used to calculate the user's `verifier`. The client sends these values to the server for long-term storage.

<div style="text-align: right">[Table of Contents](#TOC)</div>

##### <a name="UserConnection"></a>SRPC User Connection

`SrpcClient.connect/2` creates an SRPC connection for a specific user:

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, anton} = SrpcClient.connect("chigurh", "call it")
{:ok, #PID<0.246.0>}
</code></pre>

Unlike the previous use of `SrpcClient.connect/0`, which returned an SRPC lib connection, `SrpcClient.connect/2` returns an SRPC __*user connection*__ that is bound to a specific user. Creating such a user connection is the SRPC means of logging in a user. During the connection process, the server sends the user's `kdf_salt` and `srp_salt` to the client so the user's [SRP](http://srp.stanford.edu/design.html) private key can be recreated as part of SRPC mutual authentication. This prevents the client from having to maintain any long term user state. SRP's zero-knowledge password authentication scheme means the user's password _never_ leaves the client and hence is never transmitted or known to the server.

Using the [SRP](http://srp.stanford.edu/design.html) protocol, the client and server dynamically calculate a shared secret from random empheral values. This cryptographically strong shared secret is used as keying material to generate the four SRPC connection keys.

User registration and login both require an existing SRPC connection to secure user information during processing. The functions `SrpcClient.register/2` and `SrpcClient.connect/2` used above automatically create an SRPC lib connection to perform their duties and close the connection when done. Functions `SrpcClient.register/3` and `SrpcClient.connect/3` accept an existing `SrpcClient.Connection` as their first argument.

As with previous connections, we can inspect a user connection using `SrpcClient.info/1`:

<pre><code class="elixir"><strong>client &there4;</strong> anton |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460062,
  conn_id: "hNpjfBmmR3pRP7fnhTGG2fgdqT",
  created: -576460062,
  crypt_count: 0,
  entity_id: "chigurh",
  keyed: -576460062,
  name: :UserConnection_1,
  pid: #PID<0.246.0>,
  reconnect: nil,
  req_mac_key: <<235, 135, 142, 163, 59, 22, 190, 42, 225, 27, 174, 142, 103,
    198, 195, 70, 3, 233, 82, 176, 156, 224, 193, 60, 133, 238, 89, 50, 23, 166,
    94, 28>>,
  req_sym_key: <<127, 130, 243, 72, 142, 50, 121, 218, 50, 228, 181, 95, 183,
    38, 23, 221, 12, 196, 226, 212, 74, 219, 251, 31, 54, 112, 40, 82, 83, 220,
    30, 166>>,
  resp_mac_key: <<253, 2, 58, 218, 103, 156, 88, 90, 106, 111, 208, 57, 223,
    129, 46, 191, 98, 101, 8, 58, 216, 82, 207, 198, 42, 171, 110, 120, 110,
    230, 69, 240>>,
  resp_sym_key: <<74, 65, 49, 93, 145, 134, 232, 26, 98, 233, 158, 41, 41, 207,
    29, 8, 189, 81, 148, 70, 192, 215, 145, 79, 26, 231, 99, 201, 2, 26, 139,
    132>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :user,
  url: "http://localhost:8082"
}
</code></pre>

and on the server:

<pre><code class="elixir"><strong>server &there4;</strong> SrpcWorld.Server.SrpcHandler.get_conn("hNpjfBmmR3pRP7fnhTGG2fgdqT")
{:ok,
 %{
   conn_id: "hNpjfBmmR3pRP7fnhTGG2fgdqT",
   entity_id: "chigurh",
   req_mac_key: <<235, 135, 142, 163, 59, 22, 190, 42, 225, 27, 174, 142, 103,
     198, 195, 70, 3, 233, 82, 176, 156, 224, 193, 60, 133, 238, 89, 50, 23,
     166, 94, 28>>,
   req_sym_key: <<127, 130, 243, 72, 142, 50, 121, 218, 50, 228, 181, 95, 183,
     38, 23, 221, 12, 196, 226, 212, 74, 219, 251, 31, 54, 112, 40, 82, 83, 220,
     30, 166>>,
   resp_mac_key: <<253, 2, 58, 218, 103, 156, 88, 90, 106, 111, 208, 57, 223,
     129, 46, 191, 98, 101, 8, 58, 216, 82, 207, 198, 42, 171, 110, 120, 110,
     230, 69, 240>>,
   resp_sym_key: <<74, 65, 49, 93, 145, 134, 232, 26, 98, 233, 158, 41, 41, 207,
     29, 8, 189, 81, 148, 70, 192, 215, 145, 79, 26, 231, 99, 201, 2, 26, 139,
     132>>,
   sha_alg: :sha256,
   sym_alg: :aes256,
   type: :user
 }}
</code></pre>

SRPC _lib_ and _user_ connections are identical in terms of use. The only difference is a lib connection represents a mutually authenticated channel between the SRPC framework libraries in use, whereas a user connection __*also*__ ensures mutual authentication via the user's password (client) and verifier (server). Both user registration and login require an existing SRPC lib or user connection. If a user connection is used, that connection must be rooted in an SRPC lib connection. This ensures no user information is ever transmitted unencrypted.

<div style="text-align: right">[Table of Contents](#TOC)</div>

##### <a name="KeyRefresh"></a>Key Refresh

As noted earlier, SRPC uses separate keys for the encryption and authentication of each message, and a separate pair of keys for messaging in each direction. These four keys can be refreshed at any time. Refreshed keys limit the per key material available for cryptanalysis as well as the vulnerability window of a compromised key.

Let's create and use a new user connection for `anton`, then send the `SrpcServer` a few Anton quotes to reverse.

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, anton} = SrpcClient.connect("chigurh", "call it")
{:ok, #PID<0.235.0>}

<strong>client &there4;</strong> [
      "That depends. Do you see me?",
      "If the rule you followed brought you to this, of what use was the rule?",
      "I know where you are.",
      "I won't tell you you can save yourself, because you can't.",
      "Would you hold still, please, sir?",
      "That's foolish. You pick the one right tool."
    ] |> Enum.map(fn quote ->
      {{:ok, reversed}, _} = anton |> SrpcClient.post("/reverse", quote)
      reversed
    end)
["?em ees uoy oD .sdneped tahT",
 "?elur eht saw esu tahw fo ,siht ot uoy thguorb dewollof uoy elur eht fI",
 ".era uoy erehw wonk I",
 ".t'nac uoy esuaceb ,flesruoy evas nac uoy uoy llet t'now I",
 "?ris ,esaelp ,llits dloh uoy dluoW",
 ".loot thgir eno eht kcip uoY .hsiloof s'tahT"]

<strong>client &there4;</strong> anton |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460736,
  conn_id: "9pp8JJ66PDM9rGMHgJjmjrj8B7",
  created: -576460741,
  crypt_count: 6,
  entity_id: "chigurh",
  keyed: -576460741,
  name: :UserConnection_1,
  pid: #PID<0.235.0>,
  reconnect: nil,
  req_mac_key: <<215, 97, 30, 11, 49, 226, 57, 142, 232, 238, 67, 97, 230, 37,
    64, 30, 34, 51, 132, 31, 209, 230, 114, 110, 172, 186, 73, 255, 99, 86, 68,
    164>>,
  req_sym_key: <<131, 54, 101, 148, 160, 69, 59, 177, 29, 25, 197, 55, 230, 65,
    3, 248, 188, 218, 253, 30, 14, 95, 91, 174, 37, 58, 53, 236, 228, 124, 192,
    13>>,
  resp_mac_key: <<183, 63, 253, 49, 40, 185, 174, 95, 248, 174, 64, 133, 151,
    29, 47, 114, 22, 150, 66, 230, 244, 125, 170, 137, 95, 167, 224, 70, 195,
    135, 152, 238>>,
  resp_sym_key: <<24, 146, 249, 187, 51, 114, 171, 222, 63, 14, 103, 136, 66,
    85, 213, 210, 226, 53, 18, 18, 131, 75, 107, 177, 227, 216, 64, 62, 16, 54,
    76, 9>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :user,
  url: "http://localhost:8082"
}
</code></pre>

We can see from the `crypt_count` above the `anton` connection keys have been used **6** times. Let's manually refresh the keys:

<pre><code class="elixir"><strong>client &there4;</strong> SrpcClient.refresh(anton)
:ok

<strong>client &there4;</strong> anton |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460669,
  conn_id: "9pp8JJ66PDM9rGMHgJjmjrj8B7",
  created: -576460741,
  crypt_count: 0,
  entity_id: "chigurh",
  keyed: -576460669,
  name: :UserConnection_1,
  pid: #PID<0.235.0>,
  reconnect: nil,
  req_mac_key: <<40, 26, 100, 16, 158, 107, 135, 122, 159, 244, 35, 25, 219,
    229, 126, 53, 53, 82, 90, 223, 29, 185, 66, 198, 234, 2, 53, 202, 155, 146,
    122, 253>>,
  req_sym_key: <<227, 247, 9, 74, 57, 203, 101, 125, 181, 150, 245, 60, 98, 164,
    32, 187, 43, 93, 181, 91, 201, 84, 63, 142, 34, 121, 1, 128, 208, 214, 20,
    253>>,
  resp_mac_key: <<144, 34, 16, 34, 200, 223, 64, 217, 34, 105, 7, 21, 113, 134,
    123, 45, 77, 56, 128, 12, 121, 224, 77, 121, 240, 228, 190, 181, 34, 170,
    63, 187>>,
  resp_sym_key: <<103, 176, 194, 216, 251, 243, 248, 219, 3, 254, 143, 217, 239,
    78, 221, 19, 186, 232, 71, 226, 98, 35, 99, 91, 30, 125, 188, 45, 10, 39,
    218, 8>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :user,
  url: "http://localhost:8082"
}
</code></pre>

After refreshing the keys, the `crypt_count` is back to zero and the four keys are different than before the refresh.

Manual key refresh is useful, but since `SrpcClient` is already keeping count it is quite easy to have the keys auto-refreshed after a specified usage. To do so, we need to add a `key_limit` option to the client configuration file:

```elixir
config :srpc_client,
  srpc_file: "priv/client.srpc",
  transport: SrpcPoison,
  key_limit: 4
```

After [restarting](#Start) the client (Cntl-C twice to stop the IEx process), we can create and use a new `anton` connection as before. Restarting the server is not necessary, but if you do, don't forget to register user `chigurh`.

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, anton} = SrpcClient.connect("chigurh", "call it")
{:ok, #PID<0.275.0>}

<strong>client &there4;</strong> anton |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460744,
  conn_id: "dMrbdnf7QDdBm6BGFrD84Nf4jQ",
  created: -576460744,
  crypt_count: 0,
  entity_id: "chigurh",
  keyed: -576460744,
  name: :UserConnection_1,
  pid: #PID<0.275.0>,
  reconnect: nil,
  req_mac_key: <<63, 139, 135, 72, 121, 83, 85, 238, 221, 66, 177, 179, 222,
    119, 48, 137, 255, 234, 138, 32, 140, 212, 97, 71, 157, 158, 99, 191, 92,
    140, 242, 146>>,
  req_sym_key: <<61, 186, 232, 202, 195, 250, 198, 248, 186, 57, 94, 235, 229,
    254, 245, 93, 1, 62, 227, 204, 71, 43, 147, 221, 8, 158, 14, 5, 116, 142,
    148, 108>>,
  resp_mac_key: <<219, 214, 155, 162, 213, 145, 184, 147, 13, 47, 119, 42, 37,
    19, 73, 98, 40, 4, 103, 148, 217, 13, 129, 200, 89, 31, 185, 205, 71, 11,
    158, 209>>,
  resp_sym_key: <<51, 157, 177, 69, 93, 91, 61, 237, 134, 219, 38, 163, 250,
    237, 153, 100, 19, 144, 116, 44, 216, 243, 174, 236, 146, 180, 123, 46, 47,
    244, 163, 96>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :user,
  url: "http://localhost:8082"
}

<strong>client &there4;</strong> [
      "That depends. Do you see me?",
      "If the rule you followed brought you to this, of what use was the rule?",
      "I know where you are.",
      "I won't tell you you can save yourself, because you can't.",
      "Would you hold still, please, sir?",
      "That's foolish. You pick the one right tool."
    ] |> Enum.map(fn quote ->
      {{:ok, reversed}, _} = anton |> SrpcClient.post("/reverse", quote)
      reversed
    end)
["?em ees uoy oD .sdneped tahT",
 "?elur eht saw esu tahw fo ,siht ot uoy thguorb dewollof uoy elur eht fI",
 ".era uoy erehw wonk I",
 ".t'nac uoy esuaceb ,flesruoy evas nac uoy uoy llet t'now I",
 "?ris ,esaelp ,llits dloh uoy dluoW",
 ".loot thgir eno eht kcip uoY .hsiloof s'tahT"]

<strong>client &there4;</strong> anton |> SrpcClient.info(:full)
%SrpcClient.Conn{
  accessed: -576460709,
  conn_id: "dMrbdnf7QDdBm6BGFrD84Nf4jQ",
  created: -576460744,
  crypt_count: 2,
  entity_id: "chigurh",
  keyed: -576460709,
  name: :UserConnection_1,
  req_mac_key: <<59, 44, 58, 80, 37, 69, 191, 25, 152, 73, 219, 119, 194, 7,
    125, 70, 171, 48, 110, 125, 151, 240, 65, 116, 162, 122, 150, 60, 181, 147,
    194, 144>>,
  req_sym_key: <<247, 179, 173, 180, 137, 105, 193, 242, 216, 132, 217, 143,
    247, 73, 244, 10, 185, 17, 233, 139, 92, 212, 151, 181, 126, 10, 70, 147,
    218, 128, 113, 133>>,
  resp_mac_key: <<95, 245, 226, 217, 21, 199, 13, 241, 186, 97, 249, 250, 201,
    140, 70, 232, 173, 215, 244, 84, 197, 203, 135, 43, 0, 90, 9, 103, 35, 61,
    39, 175>>,
  resp_sym_key: <<192, 92, 111, 31, 176, 92, 206, 170, 214, 122, 53, 160, 48, 0,
    39, 90, 96, 57, 134, 227, 235, 134, 174, 168, 34, 93, 19, 110, 34, 89, 10,
    79>>,
  sha_alg: :sha256,
  sym_alg: :aes256,
  time_offset: 0,
  type: :user,
  url: "http://localhost:8082"
}
</code></pre>

Comparing the before and after information for the `anton` connection we see the keys are refreshed and the `crypt_count` is 2. That's because we sent 6 messages with a `key_limit` of 4, so after the 4th message the keys were refreshed before sending the last 2 messages.

It is also possible to configure `SrpcClient` to refresh the keys based on time of use:

```elixir
config :srpc_client,
  srpc_file: "priv/client.srpc",
  transport: SrpcPoison,
  key_limit: 4,
  key_refresh: 60
```

The above configuration would limit the keys to a maximum of 4 uses, as well as to being used for no more than 60 seconds. These configuration settings can be used together or individually. Both take effect _before_ each message is sent, i.e., the above configuration would trigger key refresh on the 5th message within 60 seconds, or on the Nth message (N < 5) after 60 seconds.

<div style="text-align: right">[Table of Contents](#TOC)</div>

##### <a name="Reconnect"></a>Reconnect

As we've seen, we can create either an SRPC lib or user connection between the client and the server. We've also seen that both the client and the server maintain information regarding this connection. For obvious reasons, the server can't keep client connection information indefinitely. The `SrpcWorld.Server` is configured (in the `kncache` configuration section) to keep each client's connection information for **3600** seconds. The server updates the client connection access time whenever it receives a message from the client, so the **3600** seconds actually represents an _inactivity_ time after which the server will purge the connection information if no messages have been received from the client.

We can mimic the server purging a client connection by using the `SrpcHandler` configured for the server. First we'll create a connection and get the resulting `conn_id`:

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, conn} = SrpcClient.connect()
{:ok, #PID<0.279.0>}

<strong>client &there4;</strong> conn |> SrpcClient.info(:full) |> Map.get(:conn_id)
"PtMq76Nmth6bDDrnhBbq4mtmGM"
</code></pre>

Then on the server, we'll purge that connection:

<pre><code class="elixir"><strong>server &there4;</strong> SrpcWorld.Server.SrpcHandler.delete_conn("PtMq76Nmth6bDDrnhBbq4mtmGM")
:ok
</code></pre>

Now, back on the client, we'll attempt to reverse a string with the now defunct connection:

<pre><code class="elixir"><strong>client &there4;</strong> conn |> SrpcClient.post("/reverse", "string")
{{:invalid, "Stale connection"}, #PID<0.279.0>}
</code></pre>

The client could check its own maintained access time for its connection before each use and create a new connection if necessary, but that would require the client know the connection retention time of the server. Furthermore, in the event of server restart, any existing client connections will be defunct.

`SrpcClient` provides a means to auto-reconnect a stale connection on-the-fly. In the `:srpc_client` [configuration](#ClientConfig) we'll add a `reconnect` option:

```elixir
config :srpc_client,
  srpc_file: "priv/client.srpc",
  transport: SrpcPoison,
  key_limit: 4,
  key_refresh: 60,
  reconnect: true
```

With `reconnect` set to `true`, the first time the SRPC framework detects we are using a stale client it will attempt to reconnect. To see this in action, we'll need to [restart](#Start) the client (Cntl-C twice to stop the IEx process) to pick up the above configuration change.

On the client:

<pre><code class="elixir"><strong>client &there4;</strong> {:ok, conn} = SrpcClient.connect()
{:ok, #PID<0.269.0>}

<strong>client &there4;</strong> conn |> SrpcClient.info(:full) |> Map.get(:conn_id)
"2d3fNt4g4H7MNr7JBfLLbR29hp"
</code></pre>

On the server:

<pre><code class="elixir"><strong>server &there4;</strong> SrpcWorld.Server.SrpcHandler.delete_conn("2d3fNt4g4H7MNr7JBfLLbR29hp")
:ok
</code></pre>

And finally, on the client:

<pre><code class="elixir"><strong>client &there4;</strong> {{:ok, result}, conn} = conn |> SrpcClient.post("/reverse", "string")
{{:ok, "gnirts"}, #PID<0.273.0>}
</code></pre>

Notice we changed the code to rebind `conn` by pattern matching the return from the `SrpcClient.post/3` call. If an auto-reconnect occurs, the returned **pid** will be for the new connection and the old connection will be discarded. We can see in the interactions above the original `conn` pid _#PID<0.269.0>_ was updated to _#PID<0.273.0>_. If no reconnection is required (i.e., the `conn` is still valid on the server), the returned **pid** will be the same as that passed to `SrpcClient`.

##### <a name="Fin"></a>Fin

That's it for the `SrpcWorld` demo of the SRPC framework. Please feel free to send questions or comments to Paul at _**paul@knoxen.com**_.
