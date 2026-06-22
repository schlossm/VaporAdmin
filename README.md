# VaporAdmin
A `django.contrib.admin`-like tool for managing your site's Fluent models from a GUI.

VaporAdmin enables CRUD operations on models registered with the library.

### Notices

> [!CAUTION]
> `Passage` by default exposes POST routes for authentication for client-based auth.  VaporAdmin does NOT attempt to block non-HTML calls, but does NOT provide a valid JWT generator; you should consider blocking browser-less calls to `/admin/*` routes at your server level.

> [!WARNING]
> If you use `Passage` authentication for other parts of your app, those users will be able to log into the Admin Site.  VaporAdmin doesn't yet segment users.

## Installation
Add VaporAdmin to your Package.swift:

```swift
.package(url: "https://github.com/schlossm/VaporAdmin.git", from: "0.2.0")
```

Then, add the `VaporAdmin` package to your dependencies:

```swift
.product(name: "VaporAdmin", package: "VaporAdmin")
```

### Traits

VaporAdmin comes with 2 traits for customizing the installation.  Supply an empty (`""`) trait set to exclude any extras.  The default trait is `"PassageFluent"`.

#### `"PassageFluent"`

This is the default, and recommended trait, when installing VaporAdmin.  This will include `Passage` for authentication, and the `PassageFluent` library to connect to an existing Fluent database.

If your site has no authentication strategy, use this default trait.

#### `"Passage"`

This trait includes just the `Passage` library, but requires additional configuration to connect `Passage` to an existing database and User model.

It's not recommended to use this trait unless you already have an authentication setup in your app, or your app doesn't use `Fluent`.

#### `""`

Using an empty trait set will exclude any `Passage`-related authentication integrations.  You will be required to pass in a custom `Authentication` object to tell the Admin Site how authentication works in your app..

> ![WARNING]
> Don't use an empty set unless your app already has authentication, and that authentication DOES NOT use `Passage`.  If you have Passage already included and configured in your app, consider either of the two Traits instead.

## Usage

The Admin Site requires three steps to allow your models to be managed by the GUI:

### 1. Add `@AdminDisplayable` to your model

```swift
import Fluent
import Vapor

@AdminDisplayable
final class Foo : Model, @unchecked Sendable
{
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "text")
    var text : String
}
```

`AdminDisplay` generates the required conformances and static properties for the Admin Site to manage your model.

> [!TIP]
> VaporAdmin uses the Model's `Codable` conformance.  If you manually implement `Encodable` or `Decodable`, you must implement the counterpart, or the Admin Site will fail to manage your models.

#### 1.a (Optional) Conform your model to `CustomAdminDisplayable` to customize the visual representation of your model

By default, the Admin Site uses the `description` property on your model to render a visual representation.  To customize this, you can conform to `CustomAdminDisplayable` and implement the `displayString` property.

> ![TIP]
> It's recommended that you use a property that allows for easy human identification of each instance.

```swift
extension Foo : CustomAdminDisplayable
{
    var displayString : String { text }
}
```

### 2. Configure the Admin Site

On startup, call `app.admin.configure(app:configuration:)`.  

See the `Configuration` section for the possible configuration options supported by the Admin Site

### 3. Register your model

After you conform to `@AdminDisplayable` and configure the Admin Site, you can register your model by calling `app.admin.register(_:)`:

```swift
app.admin.register(Foo.self)
```

That's it! The Admin Site will render your model at `<origin>/admin/<modelName>`

## Configuring the Admin Site

By default, the Admin Site will be configured with a suitable set of defaults to get up and running using `Passage` as the authentication library.

To use the provided defaults, for example if the Admin Site is the only part of your app using authentication, or the only part of your app that uses `Passage` for authentication, the `.init(originURL:base:)` initializer is provided on `Admin.Configuration`.

```swift
// Simple configuration: the Admin Site configures `Passage` and installs its pages at `<host>/admin/`
let configuration = Admin.Configuration(originURL: URL("https://www.example.com")!)

--

// Medium configuration: Your app configures `Passage`, only allowing login, and installs the Admin Site at `<host>/admin-site/`
let adminSiteBasePath = "admin-site"
let store = PassageFluent.DatabaseStore(app: app, db: app.db)
let services = Passage.Services(store: store, emailDelivery: nil, phoneDelivery: nil)
let passageConfiguration = Passage.Configuration(origin: origin,
                                                 routes: .init(group: "\(adminSiteBasePath)"),
                                                 sessions: .init(enabled: true),
                                                 throttle: .init(login: .init(
                                                     perIdentifier: .init(maxFailures: 5, window: 15 * 60),   // 5 failures / 15 min per account
                                                     perSource: .init(maxFailures: 5, window: 15 * 60),       // 5 failures / 15 min per IP
                                                     enabled: true)),
                                                 views: .init(login: .init(
                                                     style: .minimalism,
                                                     theme: .init(colors: .mintDark),
                                                     redirect: .init(onSuccess: "/\(adminSiteBasePath)/"),
                                                     identifier: .username))

let authentication = Admin.Configuration.Authentication(passageCustomServices: services, configuration: configuration)
let configuration = Admin.Configuration(authentication: authentication, base: adminSiteBasePath)

--

// Custom configuration: Your app has its own custom authentication strategy and installs the Admin Site at `<host>/admin-site`
let authenticators = [MySessionAuthenticator(), MyBearerAuthenticator(), MyImFeelingLuckyAuthenticator()]

let authentication = Admin.Configuration.Authentication(customAuthenticators: authenticators,
                                                        userModelType: MyUser.self,
                                                        guard: MyMyUserGuardMiddleware(),
                                                        usernameFromRequest: { req in try req.myAuthManager.user.email })
let configuration = Admin.Configuration(authentication: authentication, base: "admin-site")

```

-

### `Admin.Configuration` Object

To customize initializing of the admin tool, create an `Admin.Configuration` object.

#### `Admin.Configuration` Properties

##### `authentication`

The authentication strategy to employ.  By default, the Admin Site will configure `Passage` with suitable defaults for quick running, however you may want to customize Passage for your own site's needs, or you may want to use a custom authentication platform.

See the "`Admin.Configuration.Authentication` Object" section for more details on customizing authentication.

##### `base`

The base path for the Admin Site to install its views.  Defaults to `"admin"`.

-

### `Admin.Configuration.Authentication` Object

To customize the authentication strategy used by the Admin Site, create an `Admin.Configuration.Authentication` object.

#### `Admin.Configuration.Authentication` Initializers

Every initializer comes with a version for each trait: `PassageFluent` includes the most-convenient initializers, `Passage` includes initializers that require User model types and `Store` implementations, and `""` includes only the custom authentication initializer.

##### Initializing Passage with the Admin Site defaults

To use the built-in configuration of Passage, for example if no other part of your site uses Passage for authentication (or, if your site has no authentication at all), it's recommended to use the `init(passageOriginURL:)` or the `init(passageOriginURL:userModelType:store:)` initializers.

##### Initializing Passage with custom configuration

The Admin Site also supports initializing `Passage` with a custom `Passage` configuration.  Use the `init(passageCustomServices:contracts:configuration:hooks:)` or `init(passageCustomServices:contracts:configuration:hooks:userModelType:)` initializers to configure Passage's `Services`, `Contracts`, `Configuration`, `Hooks`, and the User model type (if not using `PassageFluent`).

##### Skipping Passage initialization

If your app already configures `Passage`, the Admin Site can use that configured instance to manage admin authentication.  Use the `.skippingPassageConfiguration()` or `.skippingPassageConfiguration(userModelType:)` static methods to tell the Admin Site to skip its own configuration of Passage.

##### Using a custom authentication strategy

> [!WARNING] Do not use a custom authentication strategy unless your app already employs its own authentication setup.  It's recommended `Passage` is used if your app doesn't already authenticate users.

If your app contains its own authentication setup, and you want the Admin Site to use that authentication setup to manage Admin users, use the `init(customAuthenticators:userModelType:guard:usernameFromRequest:)` initializer.

This initializer requires the following things for the Admin Site to do its best at authenticating the admin site:

* Authenticators for authenticating a user.  You can authenticate however you like, and the Admin Site supports any number authentication strategies (for example, Session-based and Bearer token-based strategies)
* A User model `Type` that conforms to the `Authenticatable` protocol in order to establish redirect middleware to the login page if a user object is missing on the `Request`
* A final `Guard` middleware that throws an error or aborts the request if no authenticated user is present on the request
* A closure that returns the username from the User model.  Used for the header in each Admin Site page

---

## What's Next

- [x] Support client customization of Passage
- [x] Support authentication setups other than Passage
- [x] Support a custom route installation path
- [ ] Support admin authentication model management (managing the users that can log into VaporAdmin from within VaporAdmin's GUI)
- [ ] Support as many `django.contrib.admin` `ModelAdmin` options as possible in Swift + Fluent + Leaf
- [ ] Support as many `django.contrib.admin` `AdminSite` options as possible in Swift + Fluent + Leaf
