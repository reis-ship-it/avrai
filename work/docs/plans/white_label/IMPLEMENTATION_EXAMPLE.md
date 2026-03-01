# White-Label & VPN/Proxy - Implementation Example

**Purpose:** Code examples showing how account/agent portability works with VPN/proxy support

---

## Example 1: User Connects Personal Account to White-Label Instance

```dart
// User opens white-label branded app
// Settings → Connect Personal Account

class ConnectPersonalAccountService {
  final FederationService _federation;
  final NetworkConfigService _networkConfig;
  final AgentSyncService _agentSync;
  
  Future<ConnectResult> connectPersonalAccount({
    required String email,
    required String password,
    ProxyConfig? proxyConfig,
  }) async {
    // 1. Configure proxy if provided
    if (proxyConfig != null) {
      await _networkConfig.configureProxy(proxyConfig);
      final testResult = await proxyConfig.testConnection();
      if (!testResult) {
        return ConnectResult.error('Proxy connection failed');
      }
    }
    
    // 2. Authenticate with main SPOTS instance via federation
    final federationToken = await _federation.authenticateWithMainInstance(
      email: email,
      password: password,
      whiteLabelInstanceId: WhiteLabelConfig.current.instanceId,
    );
    
    if (federationToken == null) {
      return ConnectResult.error('Authentication failed');
    }
    
    // 3. Sync user data from main instance
    final userData = await _federation.syncUserData(federationToken.token);
    
    // 4. Sync agent/personality profile
    final agentProfile = await _agentSync.syncAgentToInstance(
      agentId: federationToken.agentId,
      instanceId: WhiteLabelConfig.current.instanceId,
      token: federationToken,
    );
    
    // 5. Store federation session locally
    await _storeFederationSession(federationToken);
    
    return ConnectResult.success(
      userId: federationToken.userId,
      agentId: federationToken.agentId,
    );
  }
}
```

---

## Example 2: HTTP Client with Proxy Configuration

```dart
// Network layer automatically uses proxy for backend connections

class ApiClient {
  final NetworkConfigService _networkConfig;
  final http.Client _httpClient;
  
  ApiClient({NetworkConfigService? networkConfig})
      : _networkConfig = networkConfig ?? NetworkConfigService.instance,
        _httpClient = _networkConfig.createHttpClient();
  
  Future<ApiResponse<T>> get<T>(String endpoint) async {
    // All requests automatically route through configured proxy
    final response = await _httpClient.get(
      Uri.parse(endpoint),
      headers: _buildHeaders(),
    );
    
    return _handleResponse<T>(response);
  }
}

// NetworkConfigService creates HTTP client with proxy
class NetworkConfigService {
  ProxyConfig? _proxyConfig;
  
  http.Client createHttpClient({ProxyConfig? proxy}) {
    final config = proxy ?? _proxyConfig;
    
    if (config == null || !config.enabled) {
      return http.Client(); // No proxy
    }
    
    // Create HTTP client with proxy
    return _createProxiedHttpClient(config);
  }
  
  http.Client _createProxiedHttpClient(ProxyConfig proxy) {
    final httpClient = HttpClient();
    
    if (proxy.type == ProxyType.http || proxy.type == ProxyType.https) {
      httpClient.findProxy = (uri) {
        return 'PROXY ${proxy.host}:${proxy.port}';
      };
      
      if (proxy.username != null && proxy.password != null) {
        httpClient.authenticate = (url, scheme, realm) {
          if (url.host == proxy.host) {
            httpClient.addCredentials(
              url,
              realm,
              HttpClientBasicCredentials(
                proxy.username!,
                proxy.password!,
              ),
            );
            return true;
          }
          return false;
        };
      }
    }
    
    return IOClient(httpClient);
  }
}
```

---

## Example 3: Agent Learning Sync Across Instances

```dart
// Agent learns on white-label instance, syncs back to main account

class AgentSyncService {
  final FederationService _federation;
  final PersonalityLearningService _learning;
  
  // User's agent participates in AI2AI learning on white-label instance
  Future<void> syncAgentLearningFromInstance({
    required String agentId,
    required String instanceId,
  }) async {
    // 1. Get agent's learning from white-label instance
    final localAgent = await _learning.getAgentProfile(agentId);
    final learningUpdates = localAgent.getRecentLearning();
    
    // 2. Get federation token for this instance
    final session = await _getFederationSession(instanceId);
    if (session == null || session.isExpired) {
      throw Exception('Federation session expired');
    }
    
    // 3. Sync learning to main instance
    await _federation.syncAgentLearning(
      agentId: agentId,
      learningUpdates: learningUpdates,
      token: session.token,
    );
    
    // 4. Main instance merges learning into agent profile
    // Agent evolution continues across all instances
  }
  
  // Periodic sync (background job)
  Future<void> periodicSync() async {
    final activeInstances = await _getConnectedInstances();
    
    for (final instance in activeInstances) {
      try {
        await syncAgentLearningFromInstance(
          agentId: instance.agentId,
          instanceId: instance.instanceId,
        );
      } catch (e) {
        // Log error, continue with other instances
        print('Sync failed for ${instance.instanceId}: $e');
      }
    }
  }
}
```

---

## Example 4: White-Label Instance Configuration

```dart
// Partner deploys white-label instance with configuration

class WhiteLabelConfig {
  static WhiteLabelConfig? _current;
  
  final String instanceId;
  final String instanceName;
  final String baseUrl;
  final FederationConfig federation;
  final NetworkRequirements network;
  final BrandingConfig branding;
  
  // Load from config file
  factory WhiteLabelConfig.fromJson(Map<String, dynamic> json) {
    return WhiteLabelConfig(
      instanceId: json['instanceId'] as String,
      instanceName: json['instanceName'] as String,
      baseUrl: json['baseUrl'] as String,
      federation: FederationConfig.fromJson(json['federation']),
      network: NetworkRequirements.fromJson(json['network']),
      branding: BrandingConfig.fromJson(json['branding']),
    );
  }
  
  // Check if proxy/VPN is required
  bool get requiresProxy => network.requiresProxy;
  bool get requiresVpn => network.requiresVpn;
  ProxyConfig? get defaultProxy => network.defaultProxy;
  
  static WhiteLabelConfig get current {
    if (_current == null) {
      // Load from config file
      final configFile = File('white_label_config.json');
      final json = jsonDecode(configFile.readAsStringSync());
      _current = WhiteLabelConfig.fromJson(json);
    }
    return _current!;
  }
}

// Usage in app initialization
void main() async {
  final config = WhiteLabelConfig.current;
  
  // Check network requirements
  if (config.requiresProxy) {
    // Prompt user to configure proxy
    await _promptProxyConfiguration();
  }
  
  // Initialize app with white-label branding
  runApp(WhiteLabelApp(config: config));
}
```

---

## Example 5: User Settings UI

```dart
// User can manage account portability and proxy settings

class AccountPortabilityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      title: 'Account & Network Settings',
      body: Column(
        children: [
          // Connected instances
          Section(
            title: 'Connected Instances',
            children: [
              ConnectedInstanceCard(
                instanceName: 'Main SPOTS',
                instanceId: 'main',
                isMain: true,
              ),
              ConnectedInstanceCard(
                instanceName: 'Partner Brand SPOTS',
                instanceId: 'partner_brand',
                syncStatus: SyncStatus.active,
                onDisconnect: () => _disconnectInstance('partner_brand'),
              ),
            ],
          ),
          
          // Network settings
          Section(
            title: 'Network Configuration',
            children: [
              ProxyConfigurationCard(
                instanceId: 'partner_brand',
                proxyConfig: _getProxyConfig('partner_brand'),
                onConfigure: (config) => _configureProxy('partner_brand', config),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Proxy configuration widget
class ProxyConfigurationCard extends StatefulWidget {
  final String instanceId;
  final ProxyConfig? proxyConfig;
  final Function(ProxyConfig) onConfigure;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text('Proxy Configuration'),
          TextField(
            decoration: InputDecoration(labelText: 'Proxy Host'),
            controller: _hostController,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Port'),
            controller: _portController,
          ),
          Checkbox(
            value: _requiresAuth,
            onChanged: (v) => setState(() => _requiresAuth = v),
            child: Text('Requires Authentication'),
          ),
          if (_requiresAuth) ...[
            TextField(
              decoration: InputDecoration(labelText: 'Username'),
              controller: _usernameController,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              controller: _passwordController,
            ),
          ],
          ElevatedButton(
            onPressed: _testAndSave,
            child: Text('Test & Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _testAndSave() async {
    final config = ProxyConfig(
      type: ProxyType.http,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _requiresAuth ? _usernameController.text : null,
      password: _requiresAuth ? _passwordController.text : null,
      enabled: true,
    );
    
    // Test connection
    final isValid = await config.testConnection();
    if (!isValid) {
      // Show error
      return;
    }
    
    // Save configuration
    onConfigure(config);
  }
}
```

---

---

## Example 6: Transfer Agent from White-Label to Personal Account

```dart
// User started on white-label instance, now wants personal account with same agent

class TransferAgentFromWhitelabelService {
  final AgentTransferService _transferService;
  final FederationService _federation;
  
  Future<TransferResult> transferAgentToPersonalAccount({
    required String whiteLabelInstanceId,
    required String whiteLabelEmail,
    required String whiteLabelPassword,
    required String newPersonalAccountEmail,
    required String newPersonalAccountPassword,
    required String agentId, // AgentId from white-label instance
  }) async {
    // 1. Verify user owns agent on white-label instance
    final ownsAgent = await _transferService.verifyAgentOwnership(
      agentId: agentId,
      instanceId: whiteLabelInstanceId,
      userEmail: whiteLabelEmail,
    );
    
    if (!ownsAgent) {
      return TransferResult.error('You do not own this agent');
    }
    
    // 2. Create personal account on main instance (no VPN required)
    final personalAccount = await _createPersonalAccount(
      email: newPersonalAccountEmail,
      password: newPersonalAccountPassword,
    );
    
    // 3. Transfer agent ownership
    final transferResult = await _transferService.transferAgentToPersonalAccount(
      whiteLabelAgentId: agentId,
      whiteLabelInstanceId: whiteLabelInstanceId,
      personalAccountEmail: newPersonalAccountEmail,
      personalAccountPassword: newPersonalAccountPassword,
    );
    
    if (!transferResult.success) {
      return transferResult;
    }
    
    // 4. Agent now works on both instances with same agentId
    // User can use agent on:
    // - Personal account (no VPN)
    // - White-label instance (with VPN if required)
    // - Learning syncs between both
    
    return TransferResult.success(
      agentId: agentId, // Same agentId
      personalAccountUserId: personalAccount.userId,
      message: 'Agent transferred successfully. Same agentId works on both instances.',
    );
  }
}
```

---

## Example 7: User Starts on White-Label, Claims Agent on Personal Account

```dart
// Scenario: User creates account on white-label, later wants personal account
// They want to keep the same agentId and learning history

class ClaimAgentService {
  final AgentTransferService _transferService;
  
  Future<ClaimResult> claimAgentWhenCreatingPersonalAccount({
    required String agentId, // From white-label instance
    required String whiteLabelInstanceId,
    required String whiteLabelEmail,
    required String verificationCode, // Sent to white-label email
    required String newPersonalAccountEmail,
    required String newPersonalAccountPassword,
  }) async {
    // 1. Verify user with white-label credentials
    final verification = await _verifyWhiteLabelCredentials(
      email: whiteLabelEmail,
      agentId: agentId,
      instanceId: whiteLabelInstanceId,
      verificationCode: verificationCode,
    );
    
    if (!verification.isValid) {
      return ClaimResult.error('Verification failed');
    }
    
    // 2. Create personal account (not on VPN)
    final personalAccount = await _createPersonalAccount(
      email: newPersonalAccountEmail,
      password: newPersonalAccountPassword,
    );
    
    // 3. Claim agentId - ownership transfers to personal account
    final claimResult = await _transferService.claimAgentId(
      agentId: agentId,
      sourceInstanceId: whiteLabelInstanceId,
      newPersonalAccountEmail: newPersonalAccountEmail,
      verificationCode: verificationCode,
    );
    
    // 4. Agent profile and learning history preserved
    // AgentId remains the same
    // User can now use agent on personal account (no VPN)
    // Or continue using on white-label (with VPN if required)
    
    return ClaimResult.success(
      agentId: agentId, // Same agentId
      personalAccountUserId: personalAccount.userId,
      message: 'Agent claimed. You can use it on your personal account or white-label instance.',
    );
  }
}
```

---

## Example 8: AgentId Consistency Across Instances

```dart
// AgentId works the same regardless of origin instance

class AgentIdConsistencyService {
  // User's agent started on white-label, transferred to personal
  // Now they can use it on both instances seamlessly
  
  Future<void> demonstrateAgentContinuity() async {
    final agentId = 'agent_xyz'; // Created on white-label
    
    // Use on white-label instance (with VPN)
    final whiteLabelAgent = await _getAgentOnInstance(
      agentId: agentId,
      instanceId: 'white_label_partner',
    );
    
    // Use on personal account (no VPN)
    final personalAgent = await _getAgentOnInstance(
      agentId: agentId,
      instanceId: 'main_instance',
    );
    
    // Same agentId, same personality profile
    assert(whiteLabelAgent.agentId == personalAgent.agentId);
    assert(whiteLabelAgent.personalityDimensions == personalAgent.personalityDimensions);
    
    // Learning syncs between instances
    // Agent continues to evolve on both
    
    // User can switch instances seamlessly
    // Agent learning history is preserved
  }
}
```

---

---

## Example 9: Location Inference from Agent Network (VPN/Proxy)

```dart
// User on VPN showing France, but connected to agents in NYC
// System infers actual location from agent connections

class LocationInferenceExample {
  final LocationInferenceService _locationService;
  
  Future<void> demonstrateLocationInference() async {
    final userId = 'user_123';
    final agentId = 'agent_xyz';
    
    // User has VPN enabled (IP geolocation shows: France)
    // But user is actually in NYC
    
    // 1. System detects VPN/proxy
    final isVpnEnabled = await NetworkConfigService.instance.isVpnEnabled();
    // Returns: true (VPN is active)
    
    // 2. Get connected agents via proximity (Bluetooth/WiFi)
    final connectedAgents = await _locationService._getConnectedAgentsViaProximity(agentId);
    
    // Connected agents:
    // - Agent A: NYC (proximity: 0.8) - Coffee shop nearby
    // - Agent B: NYC (proximity: 0.7) - Bookstore nearby
    // - Agent C: NYC (proximity: 0.9) - Restaurant nearby
    // - Agent D: NYC (proximity: 0.6) - Park nearby
    // - Agent E: NYC (proximity: 0.8) - Theater nearby
    
    // 3. Infer location from agent consensus
    final inferredLocation = await _locationService.inferLocationFromAgentNetwork(
      userId: userId,
      agentId: agentId,
    );
    
    // Result:
    // - City: "NYC"
    // - Confidence: 1.0 (100% - all 5 agents are in NYC)
    // - Source: LocationSource.agentNetwork
    // - Agent count: 5
    
    // 4. System uses NYC location (not France from VPN)
    // Recommendations, discovery, community all use NYC
    
    print('Location inferred: ${inferredLocation.city} (confidence: ${inferredLocation.confidence})');
    // Output: "Location inferred: NYC (confidence: 1.0)"
  }
}

// Location determination priority
class LocationPriorityService {
  Future<Location> getCurrentLocation(String userId) async {
    // 1. Try GPS first (most accurate)
    final gpsLocation = await _getGpsLocation();
    if (gpsLocation != null && gpsLocation.accuracy < 100) {
      return gpsLocation;
    }
    
    // 2. Check if VPN/proxy is enabled
    final isVpnEnabled = await NetworkConfigService.instance.isVpnEnabled();
    final proxyConfig = await NetworkConfigService.instance.getProxyConfig();
    final isUsingProxy = proxyConfig != null && proxyConfig.enabled;
    
    if (isVpnEnabled || isUsingProxy) {
      // Use agent network inference (proximity-based)
      final inferredLocation = await LocationInferenceService().inferLocationFromAgentNetwork(
        userId: userId,
        agentId: await _getUserAgentId(userId),
      );
      
      if (inferredLocation != null && inferredLocation.confidence > 0.6) {
        return Location.fromInferred(inferredLocation);
      }
    }
    
    // 3. Fall back to IP geolocation (if no VPN/proxy)
    return await _getIpGeolocation();
  }
}

// Real-world example
class RealWorldLocationInference {
  Future<void> example() async {
    // User scenario:
    // - VPN shows: Paris, France (IP geolocation)
    // - User is actually: NYC, USA (physical location)
    // - Nearby agents: All in NYC (via Bluetooth/WiFi proximity)
    
    final locationService = LocationInferenceService();
    final location = await locationService.inferLocationFromAgentNetwork(
      userId: 'user_on_vpn',
      agentId: 'agent_nyc',
    );
    
    // System correctly infers: NYC
    // Even though VPN says: France
    // Because all nearby agents are in NYC
    
    assert(location.city == 'NYC');
    assert(location.confidence > 0.6);
    assert(location.source == LocationSource.agentNetwork);
  }
}
```

---

## Summary

This architecture enables:

1. ✅ **Account Portability** - Users authenticate with personal account on white-label instances
2. ✅ **Agent Portability (Bidirectional)** - AI personality agent syncs and learns across instances
3. ✅ **Agent Transfer** - Users can transfer agent from white-label to personal account (or vice versa)
4. ✅ **AgentId Consistency** - Same agentId works regardless of origin instance or transfer
5. ✅ **VPN/Proxy Support** - Backend connections route through configured proxy
6. ✅ **White-Label Flexibility** - Partners can require proxy/VPN for their instance
7. ✅ **User Control** - Users manage connections and network settings per instance

**Key Principles:**

1. **Users own their account and agent** - They can use them across any white-label instance while maintaining privacy and control.

2. **Agent portability is bidirectional** - Users can start on white-label or personal account and move between them seamlessly.

3. **AgentId is persistent** - Once created, the agentId remains the same regardless of instance or transfer. A user who starts on white-label (with VPN) can claim/transfer that same agentId to their personal account (not on VPN).

4. **Learning is preserved** - Agent learning history and personality evolution are maintained during transfers, so users don't lose their AI's growth.

5. **Location from agent network** - When VPN/proxy masks IP geolocation, location is inferred from connected agents via proximity (Bluetooth/WiFi). If all nearby agents are in NYC, the user is in NYC (not where the VPN says they are). This leverages existing proximity-based discovery for accurate location without relying on IP geolocation.
