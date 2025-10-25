# Cesta Trailblazer (2)
Cesta k refaktoringu

V části 1 jsem ukázal, jak jsem refaktoroval operaci Create soutěže pomocí objektu Operation a Form. V tomto příspěvku ukážu, jak jsem refaktoroval vykreslování objektu formuláře a jak jsem refaktoroval operaci Update soutěže.

## Vykreslení prázdného formuláře
V části 1 jsme refaktorovali operaci Create soutěže. Nyní je čas vykreslit formulář v `CompetitionsController#new`.

V tomto kroku chci refaktorovat:

- Metodu `new` z `CompetitionsController`
- Vyplnit html formulář objektem formuláře namísto objektem soutěže.

Nechci refaktorovat nic jiného. Chci zachovat své částečné šablony (zatím žádné refaktoring s buňkami) a zachovat pundit pro autorizaci v kontroléru.

Tady je kód, který chci refaktorovat:

```ruby
# app/controllers/competitions_controller.rb
def new
  # I want to render a @form object instead of @competition and @tracks
  @competition = current_user.creations.new
  authorize @competition, :create?

  @competition.build_start_city
  @competition.build_end_city

  # The rendered form contains one track by default, the user can add more 
  # if he wants, but must keep at least one.
  @competition.tracks.build
  @competition.tracks.last.build_start_city
  @competition.tracks.last.build_end_city
  @tracks = @competition.tracks
end
```

```html
<!-- app/views/competitions/new.html.erb -->
<div class="container padded-mini">
  <div class="row">
    <div class="col-sm-8 col-sm-offset-2">
      <h3><%= t('.title') %></h3>

      <%= render 'form', competition: @competition, tracks: @tracks %>
    </div>
  </div>
</div>
```

Formulář je velmi rozsáhlý, proto jej sem nebudu vkládat. Je však k dispozici na [githubu](https://github.com/NoryDev/somewherexpress/blob/1a85cbba55e57e5a2a98373d1779c314f9f3bd5c/app/views/competitions/_form.html.erb).

### Metoda controlleru a obecný view
V metodě řadiče můžeme znovu použít formulář, který jsme vytvořili pro Competition::Create, jak je vysvětleno v knize Trailblazer na straně 55:

```ruby
# app/controllers/competitions_controller.rb
def new
  authorize Competition, :create?

  @form = form Competition::Create
end
```

Poté můžeme tento objekt `@form` použít v zobrazení.

```html
<!-- app/views/competitions/new.html.erb -->
<h3><%= t('.title') %></h3>

<%= render 'form', competition: @form %>
```

měli bychom přejmenovat `:competition` na `:form`, ale to by narušilo zobrazení `edit`, které používá stejný formulář. Jak ale brzy uvidíme, stejně to nebude fungovat. Jako dočasné řešení bychom mohli mít dva různé částečné formuláře pro `new` a `edit`. Raději ale přepracujeme jak `new`, tak `edit`, abychom se tomuto nepříjemnému problému vyhnuli.

Prozatím se podívejme, co se pokazí v částečném formuláři. Za prvé, již nepředáváme atribut `:tracks`, takže to změňme:

```html
<!-- app/views/competitions/_form.html.erb -->
<%= f.simple_fields_for :tracks do |t| %>
<!-- was f.simple_fields_for :tracks, tracks do |t| -->
<!-- this will break on edit -->
```

Nyní máme v tomto částečném formuláři také formulář pro zrušení soutěže. Nefunguje, protože je obalen autorizační podmínkou, která vyžaduje instanci Competition (a ne objekt formuláře).

Tento formulář pro zrušení se nikdy nezobrazí v případě prázdného formuláře. V tomto částečném kódu nemá co dělat, měl by být ve svém vlastním částečném kódu a zobrazovat se pouze v případě aktualizace soutěže. Takže ho prostě extrahuji do jeho vlastního částečného kódu a nezobrazuji ho v hlavním částečném kódu formuláře (tento commit ukazuje, co jsem udělal).

Tato malá refaktorizace se možná nezdá příliš relevantní, ale zahrnul jsem ji do tohoto blogového příspěvku, protože pro mě je to příklad toho, jak mi Trailblazer pomáhá strukturovat můj kód smysluplným způsobem. Skutečnost, že mám objekt formuláře namísto objektu soutěže, mě nutí oddělit zájmy, strukturovat můj kód a uklidit nepořádek. Další 👍 pro tebe, Trailblazere.

### Vytváření vnořených objektů
Nyní se stránka vykresluje. Ale nemá žádné vnořené formuláře. To dává smysl; ve starém chování řadiče jsme měli nějaké ruční vytváření měst, jedné trati a měst této trati:

```ruby
# app/controllers/competitions_controller.rb
def new
  # [...]
  # We removed that part:
  @competition.build_start_city
  @competition.build_end_city

  @competition.tracks.build
  @competition.tracks.last.build_start_city
  @competition.tracks.last.build_end_city
end
```

V `Competition::Contract::Create` nám Reform umožňuje vytvářet vnořené objekty s atributem `:prepopulator`.

Nyní přichází ta složitější část, jejíž pochopení mi zabralo hodně času a úsilí, a to rozdíly mezi `:populate_if_empty` a `:prepopulator`. Formulářové objekty totiž fungují ve dvou směrech:

1. **Příchozí:** Deserializují a ověřují příchozí data.
2. **Odchozí:** Zobrazují odchozí data z databáze v html formuláři.
U vnořených formulářů se `:populate_if_empty` používá v příchozím směru k vyplnění pro ověření a `:prepopulator` v odchozím směru k vyplnění html formuláře. Bylo to pro mě velmi matoucí, protože se oba nazývají „populate“-něco a stále mi jejich názvy nepřijdou příliš intuitivní.

V knize Trailblazer, na straně 94, je klíčový pro pochopení tohoto rozdílu odstavec nazvaný „Prepopulation vs. Validation Population“ (Předvyplnění vs. ověřovací vyplnění).

Podívejme se, jak použít `:prepopulator` s `start_city` a `end_city`. Stejně jako u `:populate_if_empty` můžeme předat metodu do `:prepopulator`. V případě html formuláře pro vytvoření nové soutěže chceme nové prázdné město. Zde je syntaxe:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      property :start_city, prepopulator: :prepopulate_start_city!,
                            populate_if_empty: :populate_city!,
                            form: City::Form

      property :end_city, prepopulator: :prepopulate_end_city!,
                          populate_if_empty: :populate_city!,
                          form: City::Form
      # [...]
      private

        def prepopulate_start_city!(_options)
          self.start_city = City.new
        end

        def prepopulate_end_city!(_options)
          self.end_city = City.new
        end

        # [...]
    end
  end
end
```

Nyní náš formulář vykresluje město, ale ne trasy. Můžeme použít stejnou metodu `:prepopulator` na kolekci. V tomto případě bychom také měli vytvořit `start_city` a `end_city` pro nově předvyplněnou trasu:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      collection :tracks, prepopulator: :prepopulate_tracks!,
                          populate_if_empty: :populate_track! do
        # [...]
      end

      private

        def prepopulate_tracks!(_options)
          track = Track.new
          track.build_start_city
          track.build_end_city
          tracks << track
        end
        # [...]
    end
  end
end
```

### Pomocníci ve formuláři
Pokud se nyní pokusíme vykreslit náš formulář... Nefunguje to! Ve svém formuláři používám pomocníka `t.object.new_record?`, abych zjistil, zda je skladba nová nebo již existující. To je užitečné, když uživatel odstraní skladbu z formuláře, abychom věděli, zda můžeme pouze skrýt formulář skladby, nebo zda musíme provést požadavek na odstranění, abychom ji z databáze smazali.

Nyní, když mám místo objektu competition objekt form, objekt form nerozumí metodě `new_record?`. Řešení tohoto problému najdeme v knize Trailblazer na straně 144. Aktualizujme kolekci:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      collection :tracks, prepopulator: :prepopulate_tracks!,
                          populate_if_empty: :populate_track! do
                          # See p. 145 why I don't need inherit: true, not
                          # inheriting anything here
        def new_record?
          !model.persisted?
        end

        # [...]
      end
    end
  end
end
```

Náš formulář je kompletní a zobrazuje vše, co chceme. Pole pro `:description` však již není textová oblast, ale textové pole. Také povinná pole jsou nesprávná. V knize o tom nic nenajdeme, ale v této části dokumentace Reformu vidíme, že do naší smlouvy můžeme přidat modul pro simple_form. Tím se vyřeší tyto 2 problémy:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      include ActiveModel::ModelReflections
      # [...]
    end
  end
end
```

Poznámka: Než jsem začal s touto sérií refaktorování, měl jsem docela ošklivý hack: v metodách kontroléru jsem ručně přidával prázdnou stopu do svého soutěžního objektu a pak ji odstranil pomocí javascriptu v zobrazení. Protože je můj kód nyní čistý a pěkný, nechtěl jsem tento hack znovu implementovat do metod řadiče, takže jsem opravil část javascriptu, která vyžadovala přidání této prázdné stopy ([v tomto commitu](https://github.com/NoryDev/somewherexpress/commit/5c151dc5167152905c0c78555dab9b96977497aa)). To je další příklad toho, jak mě Trailblazer donutil uklidit svůj nepořádek.

## Vykreslení formuláře pro úpravu existujícího objektu
Metoda `edit` nyní nefunguje, protože jsme upravili část formuláře. Pojďme tuto část přepracovat. Je velmi podobná metodě `new`. Zde je kód k přepracování:

```ruby
# app/controllers/competitions_controller.rb
class CompetitionsController < ApplicationController
  before_action :set_competition, only: [:show, :edit, :update, :destroy]
  
  def edit
    authorize @competition, :update?

    @tracks = @competition.tracks.order(:start_time, :created_at)

    # This under was part of the "add an empty track" hack that we fixed.
    # Should be removed.
    track = @competition.tracks.build
    track.build_start_city
    track.build_end_city
    @tracks << track
  end

  private

    # I don't want to refactor this before_action method for now
    def set_competition
      @competition = Competition.find(params[:id])
    end
end
```

```html
<!-- views/competitions/edit.html.erb -->
<div class="container padded-mini">
  <div class="row">
    <div class="col-sm-8 col-sm-offset-2">
      <h3><%= t('.title') %></h3>

      <%= render 'form', competition: @competition, tracks: @tracks %>
    </div>
  </div>
</div>
```

View by měl vypadat takto:

```html
<!-- views/competitions/edit.html.erb -->
<h3><%= t('.title') %></h3>

<%= render 'form', competition: @form %>
```

Chcete-li předat formulář do zobrazení, můžeme ručně zavolat náš existující formulář Create. Ve skutečnosti bychom měli předat formulář Update. Formulář Update však bude úplně stejný jako formulář Create, s výjimkou předvyplnění (atributy `:prepopulator`). V případě editačního formuláře není předvyplnění nutné.

Zajímavý fakt:

V metodě `new` jsme přiřazovali část formuláře operace `Competition::Create` takto:

```ruby
def new
  @form = form Competition::Create
end
```

Tím se ve skutečnosti provedou dvě operace:

1. Vytvoření nového prázdného objektu formuláře
2. Volání metody `prepopulate!` na tomto objektu formuláře. Jedná se o zkratku pro:

```ruby
def new
  @form = Competition::Create::Contract.new
  @form.prepopulate!
end
```

Protože v případě `edit` nechceme předvyplnění, můžeme jednoduše provést:

```ruby
def edit
  authorize @competition, :update?

  @form = Competition::Contract::Create.new(@competition)
end
```

Připadá mi to trochu hackerské a raději bych měl `Contract::Update`. Ale to uděláme, až budeme refaktorovat operaci aktualizace.

Pamatujete si formulář pro zrušení soutěže? Potřebujeme ho tady a tento formulář bude potřebovat objekt `@competition`:

```html
<!-- views/competitions/edit.html.erb -->
<h3><%= t('.title') %></h3>

<%= render 'form', competition: @form %>
<%= render 'destroy_form', competition: @competition %>
```

## Refaktorování operace Update
Operace Update je velmi podobná operaci Create. Jak jsme právě viděli, používá téměř stejnou smlouvu. Rozdíl je však v callbacku.

Toto je kód k refaktorování:

```ruby
# app/controllers/competitions_controller.rb
def update
  authorize @competition

  updater = Competitions::Update.new(@competition, params).call
  @competition = updater.competition
  @tracks = updater.updated_tracks

  if @competition.valid? && @tracks.map(&:valid?).all?
    if @competition.just_published?
      send_new_competition_emails
    elsif @competition.published? && !@competition.finished? && @competition.enough_changes?
      send_competition_edited_emails
    end

    redirect_to @competition
  else
    # This is again for the now deprecated javascript hack
    track = Track.new(end_city: City.new, start_city: City.new)
    @tracks << track

    render :edit
  end
end

private

  # send_new_competition_emails, same method as for create

  def send_competition_edited_emails
    User.want_email_for_competition_edited(@competition).each do |user|
      UserMailer.as_user_competition_edited(user.id, @competition.id).deliver_later
    end
  end
```

Začněme operací `Competition::Update`. Může dědit z `Competition::Create`, protože v zásadě dělá totéž. Test pro tuto operaci by vypadal takto:

```ruby
RSpec.describe Competition::Update do
  let!(:user) { FactoryGirl.create(:user) }

  it "updates a competition" do
    # Use Competition::Create as factory:
    competition = Competition::Create
                  .call(competition: {
                          name: "new competition",
                          published: "1",
                          start_date: 2.weeks.from_now.to_s,
                          end_date: 3.weeks.from_now.to_s,
                          start_registration: Time.current,
                          finished: false,
                          start_city: { name: "Yverdon, CH",
                                        locality: "Yverdon-Les-Bains",
                                        country_short: "CH" },
                          end_city: { name: "Munich, DE",
                                      locality: "Munich",
                                      country_short: "DE" },
                          tracks: [{ start_time: 16.days.from_now.to_s,
                                     start_city: { name: "Yverdon, CH",
                                                   locality: "Yverdon-Les-Bains",
                                                   country_short: "CH" },
                                     end_city: { name: "Munich, DE",
                                                 locality: "Munich",
                                                 country_short: "DE" } }]
                        },
                        current_user: user)
                  .model

    Competition::Update.call(id: competition.id,
                             competition: { name: "updated name" })

    competition.reload
    expect(competition.name).to eq("updated name")
  end
end
```

```ruby
# app/concepts/competition/operation.rb
class Competition < ActiveRecord::Base
  class Update < Create
    action :update

    # We will implement a contract just for update
    contract Contract::Update

    def process(params)
      validate(params[:competition]) do |f|
        f.save

        # let's directly put the email sending callback in there:
        if model.just_published?
          send_new_competition_emails
        elsif model.published? && !model.finished? && model.enough_changes?
          send_competition_edited_emails
        end
      end
    end

    private

      # send_new_competition_emails is inherited from Create and not 
      # overridden.

      def send_competition_edited_emails
        User.want_email_for_competition_edited(model).each do |user|
          UserMailer.as_user_competition_edited(user.id, model.id).deliver_later
        end
      end
  end
end
```

A smlouva může také zdědit z Create a přepsat pouze nezbytné části:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Update < Create
      private

        # As said previously, no prepopulation for Update:
        def prepopulate_tracks!(_options)
        end

        def prepopulate_start_city!(_options)
        end

        def prepopulate_end_city!(_options)
        end
    end
  end
end
```

Test proběhl úspěšně. Je velmi příjemné používat `Competition::Create` namísto továrny, ale s tolika parametry bych přesto rád měl nějakou továrnu, abych se vyhnul zadávání falešných dat pro mé parametry pokaždé, když potřebuji soutěž. V tomto ohledu je FactoryBot velmi skvělý. Líbí se mi možnost použít `FactoryBot.create(:user)`, což vytvoří uživatele s falešnými daty. Možná někdy vyhledám, jak to udělat pomocí Operations, ale ne teď.

Nyní můžeme implementovat operaci Update v kontroléru, opět podobně jako metoda `create`:

```ruby
# app/controllers/competition_controller.rb
def update
  authorize @competition

  operation = run Competition::Update,
                  params: params.merge(current_user: current_user) do |op|
    return redirect_to op.model
  end

  @form = operation.contract
  render action: :edit
end
```

Nyní můžeme upravit metodu `edit` tak, aby používala naši nově vytvořenou operaci:

```ruby
def edit
  authorize @competition, :update?

  @form = form Competition::Update
end
```

A je to! Pěkná a přehledná třída controller, každá část ve své vlastní relevantní třídě. Můžeme provést malé úklidové práce:

* V částečném formuláři přejmenujte atribut `:competition` na `:form`, aby nedocházelo k záměně.
* Odstraňte starou službu `Competitions::Update` (starou, s „s“ v Competitions), která se již nepoužívá.
* Odstraňte validace v modelech Competition, Track a City.
* Odstraňte `accepts_nested_attributes_for` v modelech Competition a Track.

Ve skutečnosti nemohu odstranit validace a `accepts_nested_attributes_for` z modelů, protože používám [activeadmin](https://github.com/activeadmin/activeadmin), který na nich závisí. Stejně to odstraním: jsem jediný správce této aplikace, takže to bude mít vliv jen na mě, když to nebude fungovat.

Po této refaktoraci si myslím, že mohu opustit funkce create/update activeadmin a ponechat si je pouze pro Read a Destroy. S mými novými operacemi bude mnohem snazší vytvářet/aktualizovat soutěže z terminálu. Další 👍 pro vás, Trailblazere.

Konečný kód celé refaktoringové úpravy (část 1 plus část 2) je [zde](https://github.com/NoryDev/somewherexpress/tree/767fa2cd85af9cc19159a160a0f9e030e7afe6ec).

## Závěr
To je prozatím vše. Mohl bych provést další refaktoring, a také to udělám, ale to je téma na jindy. Zde je několik závěrů, které jsem z této zkušenosti vyvodil:

* Trailblazer sliboval, že budu moci provádět refaktoring po částech, a to se potvrdilo. Dávám mu 👍👍
* Trailblazer slíbil, že poskytne strukturu a konvence, a v tomto ohledu se mi líbí volby provedené Operations (zejména možnosti řetězení) a Reform. Dávám mu 👍👍
* Reform je úžasná knihovna formulářových objektů, která se mi velmi hodila v případě mé nekonvenční atribuce City. Stále si ale myslím, že názvy atributů `:populate_if_empty` a `:prepopulator` jsou matoucí. Přesto dávám 👍👍
* Trailblazer slíbil, že mohu použít Operations k nahrazení továren. Funguje to dobře, ale stále chci továrnu, která by moje Operation naplnila falešnými parametry. Dávám 👍
* Kniha je velmi užitečná a podrobná. V případě refaktoringu však bylo její použití trochu náročné, musel jsem přeskakovat mezi kapitolami. Když něco v knize není (například `simple_from`), může být obtížné najít řešení v dokumentaci. Knihu přesto hodnotím 👍, protože je to dobrý nástroj.

Jako závěrečný komentář k této celkové zkušenosti si myslím, že Trailblazer by měl být považován za samostatný framework. Měl jsem s ním jen o málo méně potíží a byl jsem o něco méně zmatený než při prvním učení se Rails. Existuje spousta konvencí a v jistém smyslu se jedná o vlastní magii pod kapotou. Myslím, že s Rails funguje dobře, jakoby rozšiřuje principy Rails CoC.

Pokud plánujete mít plně Trailblazerovou aplikaci, je třeba si uvědomit, že vaši vývojáři a vývojáři, které najmete, se to budou muset naučit, i když již znají Rails. A pro některé z nich to může být zkušenost typu „naučit se nový framework“.

To řečeno, těším se, co dalšího mohu s Trailblazerem dělat. Moje cesta ještě neskončila.