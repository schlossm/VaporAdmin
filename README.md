# VaporAdmin
A `django.contrib.admin`-like tool for managing your site's Fluent models from a GUI.

VaporAdmin enables CRUD operations on models registered with the library.

### Notices

> [!CAUTION]
> VaporAdmin uses `Passage` for authentication.  `Passage` declares itself as Alpha, so Vapor Admin is too.

> [!CAUTION]
> `Passage` by default exposes POST routes for authentication for client-based auth.  VaporAdmin does NOT attempt to block non-HTML calls, but does NOT provide a valid JWT generator; you should consider blocking browserless calls to `/admin/*` routes at your server level.

> [!WARNING]
> VaporAdmin doesn't yet allow for configuration of route paths and will unconditionally attempt to install its routes at `<origin>/admin`.

> [!WARNING]
> If you use `Passage` authentication for other parts of your app, those users will be able to log into the admin portal.  VaporAdmin doesn't yet segment users.

## Installation
Add VaporAdmin to your Package.swift:

```swift
.package(url: "https://github.com/schlossm/VaporAdmin.git", from: "0.1.0")
```

Then, add the `VaporAdmin` package to your dependencies:

```swift
.product(name: "VaporAdmin", package: "VaporAdmin")
```

## Usage

VaporAdmin requires three steps to allow your models to be managed by the GUI:

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

`AdminDisplay` generates the required conformances and static properties for VaporAdmin to manage your model.

> [!TIP]
> VaporAdmin uses the Model's `Codable` conformance.  If you manually implement `Encodable` or `Decodable`, you must implement the counterpart, or VaporAdmin will fail to manage your models.

#### 1.a (Optional) Conform your model to `CustomAdminDisplayable` to customize the visual representation of your model

By default, VaporAdmin uses the `description` property on your model to render a visual representation.  To customize this, you can conform to `CustomAdminDisplayable` and implement the `displayString` property.

Like Django's Admin portal, it's recommended you use a property that allows for easy human identification of each instance.

```swift
extension Foo : CustomAdminDisplayable
{
    var displayString : String { text }
}
```

### 2. Configure VaporAdmin

On startup, call `app.admin.configure(app:origin:)`.  

VaporAdmin currently uses `Passage` to manage authentication, and requires a single configuration property:

* `origin` - The URL your site is hosted at

Like Passage, VaporAdmin expects `sessions` to be enabled on your Vapor App, as well as a `Database` to be enabled and configured BEFORE configuring VaporAdmin.

### 3. Register your model

After you conform to `@AdminDisplayable` and configure VaporAdmin, you can register your model by calling `app.admin.register(_:)`:

```
app.admin.register(Foo.self)
```

That's it! VaporAdmin will render your model at `<origin>/admin/<modelName>`

## What's Next

- [ ] Support client customization of Passage
- [x] Support authentication setups other than Passage
- [x] Support a custom route installation path
- [ ] Support admin authentication model management (managing the users that can log into VaporAdmin from within VaporAdmin's GUI)
- [ ] Support as many `django.contrib.admin` `ModelAdmin` options as possible in Swift + Fluent + Leaf
- [ ] Support as many `django.contrib.admin` `AdminSite` options as possible in Swift + Fluent + Leaf
