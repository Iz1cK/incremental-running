local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local ConfigService = if IS_SERVER then game:FindService("ConfigService") else nil
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZapClient = if IS_SERVER then nil else require(Shared:WaitForChild("ZapClient"))
local ZapServer = if IS_SERVER then require(Shared:WaitForChild("ZapServer")) else nil

export type SchemaRule = {
	type: string,
	from: {string}?,
	required: boolean?,
	default: any?,
	transform: ((value: any?) -> any?)?,
	entry: string?,
	fields: {[string]: SchemaRule}?,
}

export type Options = {
	key: string,
	defaults: any,
	state: any?,
	schema: {[string]: SchemaRule}?,
	entryKey: string?,
	normalize: ((raw: any) -> any)?,
	clone: ((state: any) -> any)?,
	replicate: {
		toPayload: ((state: any) -> any)?,
	}?,
}

export type AttachOptions = {
	key: string,
	replicate: boolean?,
	waitTimeout: number?,
}

export type Typed<T, V = any> = {
	refresh: (self: Typed<T, V>) -> T,
	getState: (self: Typed<T, V>) -> T,
	setState: (self: Typed<T, V>, state: T) -> (),
	onChanged: (self: Typed<T, V>, callback: (state: T) -> ()) -> () -> (),
	onKeyChanged: (self: Typed<T, V>, entryKey: string, callback: (old: V?, new: V?) -> ()) -> () -> (),
	destroy: (self: Typed<T, V>) -> (),
}

local LiveConfig = {}
LiveConfig.__index = LiveConfig

local TYPE_KEY = "__liveConfigType"
local RESERVED_ATTACH_KEY = "Live"

local serverConfigs: {[string]: any} = {}
local clientCache: {[string]: any} = {}
local clientListeners: {[string]: {(any) -> ()}} = {}
local clientKeyListeners: {[string]: {[string]: {(old: any?, new: any?) -> ()}}} = {}
local clientWaiters: {[string]: {thread}} = {}
local clientConnected = false

local function isArray(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end

	local count = 0

	for key in value do
		if typeof(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end

		count += 1
	end

	for index = 1, count do
		if value[index] == nil then
			return false
		end
	end

	return true
end

local function cloneValue(source: any): any
	local valueType = typeof(source)

	if valueType == "table" then
		local result = {}

		for key, value in source do
			result[key] = cloneValue(value)
		end

		return result
	end

	if valueType == "Color3" then
		return Color3.new(source.R, source.G, source.B)
	end

	if valueType == "Vector3" then
		return Vector3.new(source.X, source.Y, source.Z)
	end

	return source
end

local function deepEqual(left: any, right: any): boolean
	if left == right then
		return true
	end

	if typeof(left) ~= typeof(right) then
		return false
	end

	if typeof(left) ~= "table" then
		return false
	end

	for key, value in left do
		if not deepEqual(value, right[key]) then
			return false
		end
	end

	for key in right do
		if left[key] == nil then
			return false
		end
	end

	return true
end

local function subscribe(list: {any}, callback: any, onEmpty: (() -> ())?): () -> ()
	list[#list + 1] = callback

	local disconnected = false

	return function()
		if disconnected then
			return
		end

		disconnected = true

		for index, registered in list do
			if registered == callback then
				table.remove(list, index)
				break
			end
		end

		if onEmpty and #list == 0 then
			onEmpty()
		end
	end
end

local function resolveSource(raw: {[string]: any}, fieldName: string, from: {string}?): any?
	if from then
		for _, alias in from do
			if raw[alias] ~= nil then
				return raw[alias]
			end
		end

		return nil
	end

	return raw[fieldName]
end

local function resolveField(raw: {[string]: any}, fieldName: string, rule: SchemaRule): any?
	local value = resolveSource(raw, fieldName, rule.from)

	if rule.transform then
		value = rule.transform(value)
	end

	if value == nil then
		return rule.default
	end

	if typeof(value) ~= rule.type then
		return rule.default
	end

	return value
end

local function normalizeEntryFromSchema(raw: any, schema: {[string]: SchemaRule}): any?
	if typeof(raw) ~= "table" then
		return nil
	end

	local result = {}

	for fieldName, rule in schema do
		if rule.type == "array" then
			local array = {}
			local source = resolveSource(raw, fieldName, rule.from)

			if typeof(source) == "table" then
				for _, item in source do
					if typeof(item) ~= "table" then
						continue
					end

					if rule.entry and typeof(item[rule.entry]) ~= "string" then
						continue
					end

					local normalized = {}

					for subField, subRule in rule.fields :: {[string]: SchemaRule} do
						normalized[subField] = resolveField(item, subField, subRule)
					end

					array[#array + 1] = normalized
				end
			end

			result[fieldName] = array
		else
			local value = resolveField(raw, fieldName, rule)

			if rule.required and value == nil then
				return nil
			end

			result[fieldName] = value
		end
	end

	return result
end

local function buildSchemaCollectionNormalizer(
	schema: {[string]: SchemaRule},
	entryKey: string,
	defaults: any
): (raw: any) -> any
	return function(rawRoot: any)
		if typeof(rawRoot) ~= "table" then
			return cloneValue(defaults)
		end

		local loaded = {}

		for _, entry in rawRoot do
			local parsed = normalizeEntryFromSchema(entry, schema)

			if parsed and typeof(parsed[entryKey]) == "string" then
				loaded[parsed[entryKey]] = parsed
			end
		end

		if next(loaded) == nil then
			return cloneValue(defaults)
		end

		return loaded
	end
end

local function serializeValue(value: any): any?
	local valueType = typeof(value)

	if valueType == "nil" then
		return nil
	end

	if valueType == "boolean" or valueType == "number" or valueType == "string" then
		return value
	end

	if valueType == "Color3" then
		return {
			[TYPE_KEY] = "Color3",
			r = value.R,
			g = value.G,
			b = value.B,
		}
	end

	if valueType == "Vector3" then
		return {
			[TYPE_KEY] = "Vector3",
			x = value.X,
			y = value.Y,
			z = value.Z,
		}
	end

	if valueType == "table" then
		if isArray(value) then
			local result = table.create(#value)

			for index, entry in ipairs(value) do
				result[index] = serializeValue(entry)
			end

			return result
		end

		local result = {}

		for key, entry in value do
			if typeof(key) ~= "string" then
				continue
			end

			local serialized = serializeValue(entry)

			if serialized ~= nil then
				result[key] = serialized
			end
		end

		return result
	end

	return nil
end

local function deserializeValue(value: any): any
	if typeof(value) ~= "table" then
		return value
	end

	local taggedType = value[TYPE_KEY]

	if taggedType == "Color3" then
		return Color3.new(value.r or 0, value.g or 0, value.b or 0)
	end

	if taggedType == "Vector3" then
		return Vector3.new(value.x or 0, value.y or 0, value.z or 0)
	end

	if isArray(value) then
		local result = table.create(#value)

		for index, entry in ipairs(value) do
			result[index] = deserializeValue(entry)
		end

		return result
	end

	local result = {}

	for key, entry in value do
		result[key] = deserializeValue(entry)
	end

	return result
end

local function encodePayload(value: any): string
	local ok, payloadJson = pcall(HttpService.JSONEncode, HttpService, serializeValue(value) or {})

	if not ok then
		error("[LiveConfig] Failed to encode payload JSON")
	end

	return payloadJson
end

local function decodePayload(payloadJson: string): any?
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, payloadJson)

	if not ok then
		warn("[LiveConfig] Failed to decode payload JSON")
		return nil
	end

	return deserializeValue(decoded)
end

local function buildModuleSnapshot(moduleTable: {[any]: any}): {[string]: any}
	local snapshot = {}

	for key, value in moduleTable do
		if key == RESERVED_ATTACH_KEY or typeof(key) ~= "string" then
			continue
		end

		local serialized = serializeValue(value)

		if serialized ~= nil then
			snapshot[key] = deserializeValue(serialized)
		end
	end

	return snapshot
end

local function mergeIntoModule(target: {[any]: any}, incoming: any)
	if typeof(incoming) ~= "table" then
		return
	end

	for key, value in incoming do
		if typeof(key) ~= "string" then
			continue
		end

		local targetValue = target[key]

		if typeof(value) == "table" and typeof(targetValue) == "table" and not isArray(value) then
			mergeIntoModule(targetValue, value)
		else
			target[key] = cloneValue(value)
		end
	end
end

local function dispatchClientState(key: string, payload: any)
	local oldPayload = clientCache[key]
	clientCache[key] = payload

	local waiters = clientWaiters[key]

	if waiters then
		clientWaiters[key] = nil

		for _, thread in waiters do
			task.spawn(thread, cloneValue(payload))
		end
	end

	local keyListeners = clientKeyListeners[key]

	if keyListeners and typeof(payload) == "table" then
		local oldTable = if typeof(oldPayload) == "table" then oldPayload else {}

		for entryKey, callbacks in keyListeners do
			local oldEntry = oldTable[entryKey]
			local newEntry = payload[entryKey]

			if deepEqual(oldEntry, newEntry) then
				continue
			end

			local oldClone = cloneValue(oldEntry)
			local newClone = cloneValue(newEntry)

			for _, callback in callbacks do
				task.spawn(callback, oldClone, newClone)
			end
		end
	end

	local listeners = clientListeners[key]

	if listeners then
		local clonedPayload = cloneValue(payload)

		for _, callback in listeners do
			task.spawn(callback, clonedPayload)
		end
	end
end

local function ensureClientConnection()
	if IS_SERVER or clientConnected then
		return
	end

	clientConnected = true

	ZapClient.LiveConfigSnapshot.SetCallback(function(packet)
		local payload = decodePayload(packet.payloadJson)

		if payload ~= nil then
			dispatchClientState(packet.key, payload)
		end
	end)
end

local function createClientProxy(key: string)
	local proxy = {}

	function proxy:getState()
		return LiveConfig.get(key)
	end

	function proxy:refresh()
		return LiveConfig.waitFor(key, 10)
	end

	function proxy:setState()
		error("[LiveConfig] setState can only be used on the server")
	end

	function proxy:onChanged(callback)
		return LiveConfig.listen(key, callback)
	end

	function proxy:onKeyChanged(entryKey, callback)
		return LiveConfig.listenKey(key, entryKey, callback)
	end

	function proxy:destroy() end

	return proxy
end

if IS_SERVER then
	ZapServer.GetLiveConfigSnapshot.SetCallback(function(_, key)
		local config = serverConfigs[key]

		if config == nil or not config._replicate then
			return {
				found = false,
				payloadJson = "",
			}
		end

		return {
			found = true,
			payloadJson = config:_buildPayloadJson(),
		}
	end)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			LiveConfig.pushAllTo(player)
		end)
	end)
end

function LiveConfig.new(options: Options)
	assert(typeof(options.key) == "string" and #options.key > 0, "[LiveConfig] options.key must be a non-empty string")
	assert(options.defaults ~= nil, "[LiveConfig] options.defaults is required")
	assert(
		options.state ~= nil or options.schema ~= nil or options.normalize ~= nil,
		"[LiveConfig] options.state, options.schema, or options.normalize is required"
	)

	if options.entryKey and not options.schema then
		warn("[LiveConfig] options.entryKey has no effect without options.schema")
	end

	local self = setmetatable({}, LiveConfig)
	self._key = options.key
	self._clone = options.clone or cloneValue
	self._state = self._clone(options.state ~= nil and options.state or options.defaults)
	self._listeners = {} :: {(any) -> ()}
	self._keyListeners = {} :: {[string]: {(old: any?, new: any?) -> ()}}
	self._destroyed = false
	self._toPayload = nil
	self._normalize = nil

	if options.schema then
		if options.entryKey then
			self._normalize = buildSchemaCollectionNormalizer(options.schema, options.entryKey, options.defaults)
		else
			self._normalize = function(raw: any)
				return normalizeEntryFromSchema(raw, options.schema) or {}
			end
		end
	elseif options.normalize then
		self._normalize = options.normalize
	end

	self._supportsRefresh = IS_SERVER and ConfigService ~= nil and self._normalize ~= nil

	if options.replicate then
		assert(not IS_SERVER or serverConfigs[options.key] == nil, `[LiveConfig] Duplicate replicated key "{options.key}"`)
		self._replicate = true
		self._toPayload = options.replicate.toPayload

		if IS_SERVER then
			serverConfigs[options.key] = self

			for _, player in ipairs(Players:GetPlayers()) do
				self:_pushTo(player)
			end
		end
	end

	return self
end

function LiveConfig:_buildPayload(): any
	local state = self._clone(self._state)

	if self._toPayload then
		return self._toPayload(state)
	end

	return state
end

function LiveConfig:_buildPayloadJson(): string
	return encodePayload(self:_buildPayload())
end

function LiveConfig:_pushTo(player: Player)
	if not IS_SERVER or not self._replicate then
		return
	end

	ZapServer.LiveConfigSnapshot.Fire(player, {
		key = self._key,
		payloadJson = self:_buildPayloadJson(),
	})
end

function LiveConfig:_apply(state: any)
	if deepEqual(self._state, state) then
		return
	end

	local oldState = self._state
	self._state = self._clone(state)

	for entryKey, listeners in self._keyListeners do
		local oldEntry = oldState[entryKey]
		local newEntry = self._state[entryKey]

		if deepEqual(oldEntry, newEntry) then
			continue
		end

		local oldClone = self._clone(oldEntry)
		local newClone = self._clone(newEntry)

		for _, callback in listeners do
			task.spawn(callback, oldClone, newClone)
		end
	end

	local snapshot = self._clone(self._state)

	for _, listener in self._listeners do
		task.spawn(listener, snapshot)
	end

	if self._replicate and IS_SERVER then
		ZapServer.LiveConfigSnapshot.FireAll({
			key = self._key,
			payloadJson = self:_buildPayloadJson(),
		})
	end
end

function LiveConfig:_extractRaw(snapshot: any): any?
	local ok, value = pcall(snapshot.GetValue, snapshot, self._key)

	if not ok or value == nil then
		return nil
	end

	if typeof(value) ~= "string" then
		return value
	end

	local decoded = decodePayload(value)

	if decoded == nil then
		local jsonOk, jsonDecoded = pcall(HttpService.JSONDecode, HttpService, value)

		if not jsonOk then
			warn(`[LiveConfig] Failed to decode ConfigService JSON for key "{self._key}"`)
			return nil
		end

		return jsonDecoded
	end

	return decoded
end

function LiveConfig:refresh(): any
	if not self._supportsRefresh then
		return self:getState()
	end

	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end

	if self._valueChangedConnection then
		self._valueChangedConnection:Disconnect()
		self._valueChangedConnection = nil
	end

	local ok, result = pcall(ConfigService.GetConfigAsync, ConfigService)
	local snapshot = if ok then result else nil

	if snapshot == nil then
		return self:getState()
	end

	local function onConfigUpdated()
		local raw = self:_extractRaw(snapshot)

		if raw ~= nil then
			self:_apply(self._normalize(raw))
		end
	end

	self._updateConnection = snapshot.UpdateAvailable:Connect(function()
		local refreshOk = pcall(snapshot.Refresh, snapshot)

		if refreshOk then
			onConfigUpdated()
		end
	end)

	self._valueChangedConnection = snapshot:GetValueChangedSignal(self._key):Connect(function()
		onConfigUpdated()
	end)

	onConfigUpdated()

	return self:getState()
end

function LiveConfig:getState(): any
	return self._clone(self._state)
end

function LiveConfig:setState(state: any)
	assert(IS_SERVER, "[LiveConfig] setState can only be used on the server")
	self:_apply(state)
end

function LiveConfig:onChanged(callback: (any) -> ()): () -> ()
	return subscribe(self._listeners, callback)
end

function LiveConfig:onKeyChanged(entryKey: string, callback: (old: any?, new: any?) -> ()): () -> ()
	local listeners = self._keyListeners[entryKey]

	if listeners == nil then
		listeners = {}
		self._keyListeners[entryKey] = listeners
	end

	return subscribe(listeners, callback, function()
		self._keyListeners[entryKey] = nil
	end)
end

function LiveConfig:destroy()
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end

	if self._valueChangedConnection then
		self._valueChangedConnection:Disconnect()
		self._valueChangedConnection = nil
	end

	table.clear(self._listeners)
	table.clear(self._keyListeners)

	if self._replicate and IS_SERVER then
		serverConfigs[self._key] = nil
	end
end

function LiveConfig.get(key: string): any?
	if IS_SERVER then
		local config = serverConfigs[key]
		return if config ~= nil then config:getState() else nil
	end

	ensureClientConnection()

	local cached = clientCache[key]
	return if cached ~= nil then cloneValue(cached) else nil
end

function LiveConfig.waitFor(key: string, timeout: number?): any?
	if IS_SERVER then
		local config = serverConfigs[key]
		return if config ~= nil then config:getState() else nil
	end

	ensureClientConnection()

	if clientCache[key] ~= nil then
		return cloneValue(clientCache[key])
	end

	local ok, response = pcall(ZapClient.GetLiveConfigSnapshot.Call, key)

	if ok and response.found then
		local payload = decodePayload(response.payloadJson)

		if payload ~= nil then
			dispatchClientState(key, payload)
			return cloneValue(payload)
		end
	end

	local waiters = clientWaiters[key]

	if waiters == nil then
		waiters = {}
		clientWaiters[key] = waiters
	end

	local thread = coroutine.running()
	waiters[#waiters + 1] = thread

	task.delay(timeout or 10, function()
		local list = clientWaiters[key]

		if list == nil then
			return
		end

		for index, waitingThread in list do
			if waitingThread == thread then
				table.remove(list, index)

				if #list == 0 then
					clientWaiters[key] = nil
				end

				task.spawn(thread, nil)
				return
			end
		end
	end)

	return coroutine.yield()
end

function LiveConfig.pushAllTo(player: Player)
	if not IS_SERVER then
		return
	end

	for _, config in serverConfigs do
		config:_pushTo(player)
	end
end

function LiveConfig.listen(key: string, callback: (any) -> ()): () -> ()
	if IS_SERVER then
		local config = serverConfigs[key]
		return if config ~= nil then config:onChanged(callback) else function() end
	end

	ensureClientConnection()

	local listeners = clientListeners[key]

	if listeners == nil then
		listeners = {}
		clientListeners[key] = listeners
	end

	return subscribe(listeners, callback)
end

function LiveConfig.listenKey(key: string, entryKey: string, callback: (old: any?, new: any?) -> ()): () -> ()
	if IS_SERVER then
		local config = serverConfigs[key]
		return if config ~= nil then config:onKeyChanged(entryKey, callback) else function() end
	end

	ensureClientConnection()

	local configKeyListeners = clientKeyListeners[key]

	if configKeyListeners == nil then
		configKeyListeners = {}
		clientKeyListeners[key] = configKeyListeners
	end

	local listeners = configKeyListeners[entryKey]

	if listeners == nil then
		listeners = {}
		configKeyListeners[entryKey] = listeners
	end

	return subscribe(listeners, callback, function()
		configKeyListeners[entryKey] = nil
	end)
end

function LiveConfig.attachModule(moduleTable: {[any]: any}, options: AttachOptions)
	assert(typeof(moduleTable) == "table", "[LiveConfig] attachModule expects a table")
	assert(typeof(options) == "table", "[LiveConfig] attachModule options are required")
	assert(typeof(options.key) == "string" and #options.key > 0, "[LiveConfig] attachModule options.key must be a non-empty string")

	local initialState = buildModuleSnapshot(moduleTable)

	if IS_SERVER then
		local handle = LiveConfig.new({
			key = options.key,
			defaults = initialState,
			state = initialState,
			replicate = if options.replicate == false then nil else {},
		})

		handle:onChanged(function(state)
			mergeIntoModule(moduleTable, state)
		end)

		return handle
	end

	local disconnect = LiveConfig.listen(options.key, function(state)
		mergeIntoModule(moduleTable, state)
	end)

	task.spawn(function()
		local state = LiveConfig.waitFor(options.key, options.waitTimeout or 10)

		if state ~= nil then
			mergeIntoModule(moduleTable, state)
		end
	end)

	local proxy = createClientProxy(options.key)
	local baseDestroy = proxy.destroy

	function proxy:destroy()
		disconnect()
		baseDestroy(self)
	end

	return proxy
end

return LiveConfig
