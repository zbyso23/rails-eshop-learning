# Validace (Validation)

Validace v Reformu probíhá v metodě `validate` a pouze tam.

Reform deserializuje fragmenty a jejich hodnoty do formuláře a jeho vnořených podformulářů a poté provede validace.

Vrátí výsledek typu boolean a poskytne potenciální chyby prostřednictvím `errors`.

---

## Validacni základ (Validation Engine)
Od verze Reform 2.0 si můžete vybrat svůj validační engine. Může to být buď `ActiveModel::Validations` nebo `dry-validation`. Příklady validace uvedené na této stránce používají `dry-validation`.

```
Reform 2.2 přestává podporovat ActiveModel. Stále jej můžete používat (a bude fungovat!), ale již jej nebudeme aktivně udržovat. Jinými slovy, ActiveModel::Validations a Reform by měly fungovat alespoň do verze Reform 4.0.
```

Vezměte na vědomí, že nejste omezeni na jeden validační engine. Při přechodu z `ActiveModel::Validation` na `dry-validation` byste měli nastavit první z nich jako výchozí validační engine.

Konfigurace předpokládá, že máte nainstalovaný `reform-rails`.

```ruby
config.reform.validations = :active_model
```

Ve formulářích, které aktualizujete na suchou validaci, můžete explicitně zahrnout validační modul.

```ruby
require 'reform/form/dry'

module Album::Contract
  class Create < Reform::Form
    feature Reform::Form::Dry # override the default.

    validation do
      required(:title).filled
    end
  end
end
```

Tím se nahradí backend ActiveModel za dry pouze pro tuto konkrétní třídu formuláře.

---

## Validační skupiny (Validation Groups)
Seskupení validací umožňuje spouštět je podmíněně nebo v určitém pořadí. Pomocí `:if` můžete určit, která skupina musí být úspěšná, aby byla validace provedena.

```ruby
validation :default do
  required(:title).filled
end

validation :unique, if: :default do
  configure do
    def unique?(value)
      # ..
    end
  end

  required(:title, &:unique?)
end
```

Tím se spustí pouze validační skupina `:unique`, která spotřebovává databázi, pokud byla platná skupina `:default`.

Řetězení skupin funguje pomocí volby `:after`. Tím se skupina spustí bez ohledu na předchozí výsledek. Upozorňujeme, že ji lze stále kombinovat s `:if`.

```ruby
validation :email, after: :default do
  configure do
    def email?(value)
      # ..
    end
  end
  required(:email, &:email?)
end
```

Kdykoli můžete rozšířit existující skupinu pomocí `:inherit`.

```ruby
validation :email, inherit: true do
  required(:email).filled
end
```

Tím se přidají validace k existující skupině `:email`.

---

## Dry-validation
Dry-validation je preferovaný backend pro definování a provádění validací.

Nejčistší formou definování validací s tímto backendem je použití validační skupiny. Skupina poskytuje přesně stejné API jako `Dry::Validation::Schema`. Veškeré podrobnosti najdete na webových stránkách gemu.

```ruby
require "reform/form/dry"

class AlbumForm < Reform::Form
  feature Reform::Form::Dry

  property :title

  validation :default do
    required(:title).filled
  end
end
```

Vlastní predikáty musí být definovány ve validační skupině. Pokud potřebujete přístup k formuláři, musíte předat `with: {form: true}` do validačního bloku.

```ruby
validation :default, with: {form: true} do
  configure do
    def unique?(value)
      Album.where.not(id: form.model.id).find_by(title: value).nil?
    end
  end

  required(:title).filled(:unique?)
end
```

Kromě API pro suché ověření máte přístup k formuláři, který obsahuje skupinu, prostřednictvím formuláře.

```ruby
validation :default, with: {form: true} do
  configure do
    def same_password?(value)
      value == form.password
    end
  end

  required(:confirm_password).filled(:same_password?)
end
```

Nezapomeňte si přečíst dokumentaci k suché validaci, protože obsahuje některé velmi účinné koncepty, jako jsou pravidla na vysoké úrovni, která vám poskytují mnohem bohatší sémantiku validace ve srovnání s AM:V.

## Dry: Chybové zprávy (Error Messages)
Musíte poskytnout vlastní chybové zprávy prostřednictvím mechanismu dry-validation.

```ruby
validation :default do
  configure do
    config.messages_file = 'config/error_messages.yml'
  end
  # ..
end
```

Toto je automaticky nakonfigurováno tak, aby používalo gem I18n, pokud je k dispozici, což je v prostředí Rails pravda.

Jednoduchý soubor chybových hlášení může vypadat následovně.
```ruby
en:
  errors:
    same_password?: "passwords not equal"
```

---

## ActiveModel
V prostředí Rails bude podpora AM načtena automaticky.

V jiných frameworkách je třeba zahrnout `Reform::Form::ActiveModel::Validations` buď do konkrétní třídy formuláře, nebo jednoduše do `Reform::Form` a zpřístupnit ji všem podtřídám.

```ruby
require "reform/form/active_model/validations"

Reform::Form.class_eval do
  feature Reform::Form::ActiveModel::Validations
end
```

## Ověření jedinečnosti (Uniqueness Validation)
Moduly ActiveRecord i Mongoid podporují „nativní“ ověření jedinečnosti, při kterém je ověření v zásadě delegováno na „skutečnou“ třídu modelu. K tomu dochází při použití `validates_uniqueness_of` a jsou respektovány možnosti jako `:scope` atd.

```ruby
class SongForm < Reform::Form
  include Reform::Form::ActiveRecord
  model :song

  property :title
  validates_uniqueness_of :title, scope: [:album_id, :artist_id]
end
```

Upozorňujeme však, že tyto validátory zapisují do instance modelu. I když to *obvykle* není trvalé, naruší to stav vaší aplikace, protože v případě neplatné validace bude váš model obsahovat neočekávané hodnoty.

Není to chyba Reformu, ale konstrukční chyba validátorů ActiveRecord.

## Jedinečná validace (Unique Validation)
Doporučujeme však používat nepsanou validaci Reformu „unique: true“.

```ruby
require "reform/form/validation/unique_validator"

class SongForm < Reform::Form
  property :title
  validates :title, unique: true
end
```

Tím se ověří pouze jedinečnost pole `title`.

Pro ověření jedinečnosti více polí použijte možnost `:scope`.
```ruby
validates :user_id, unique: { scope: [:user_id, :song_id] }
```
Neváhejte nám [pomoci zde](https://github.com/trailblazer/reform-rails/blob/master/lib/reform/form/validation/unique_validator.rb)!

---

## Potvrzení validace
Stejně tak je validace `confirm: true` z ActiveResource považována za nebezpečnou a neměla by být používána. Také zapisuje do modelu a pravděpodobně mění stav aplikace.

Místo toho použijte vlastní virtuální pole.

```ruby
class SignInForm < Reform::Form
  property :password, virtual: true
  property :password_confirmation, virtual: true

  validate :password_ok? do
    errors.add(:password, "Password mismatch") if password != password_confirmation
  end
end
```

Toto téma je popsáno v kapitole Ověřování v knize [Trailblazer](https://leanpub.com/trailblazer).

---

## Ověření nahraných souborů (Validations For File Uploads)
Pokud zpracováváte nahrané soubory pomocí formuláře s využitím CarrierWave, Paperclip, Dragonfly nebo Paperdragon, doporučujeme použít skvělý gem [file_validators](https://github.com/musaffa/file_validators) pro ověření typu a velikosti souborů.

```ruby
class SongForm < Reform::Form
  property :image

  validates :image, file_size: {less_than: 2.megabytes},
    file_content_type: {allow: ['image/jpeg', 'image/png', 'image/gif']}
```