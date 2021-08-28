# Network
Old version of my Networking module

##Usage

Client:
> local Network = Network.new("NetworkName")
> Network:Send("Method", ...)

"Method" can be defined as a BindableEvent, using _ as prefix, RemoteFunction with . as prefix and BindableFunction with _. as prefix.
NetworkName can be any name you want, it's essentially the name of the Instances, Method is the string that acts like a code for that action.

Server:
> local Network = Network.new("NetworkName")
> Network:Listen("Method", Callback)

"Method" can be defined as a BindableEvent, using _ as prefix, RemoteFunction with . as prefix and BindableFunction with _. as prefix.
NetworkName can be any name you want, it's essentially the name of the Instances, Method is the string that acts like a code for that action.
Method and NetworkName have to match between client and server.
