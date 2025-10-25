# Cesta Trailblazer (1)
Cesta k refaktoringu

Rozhodl jsem se refaktorovat jeden ze svých vedlejších projektů v Rails s architekturou [Trailblazer](https://trailblazer.to/2.1/). Proč? Stručně řečeno, hledám nějaké standardy a konvence pro refaktoring aplikace Rails API, na které pracuji v rámci své každodenní práce. Poté, co jsem si přečetl něco o Trailblazeru a o tom, co nabízí, rozhodl jsem se ho vyzkoušet na jednom ze svých vedlejších projektů. Refaktoroval bych ho, abych se seznámil s architekturou, a pak bych se rozhodl, zda je Trailblazer vhodný pro mou profesionální aplikaci.

Při první refaktoraci jsem si uvědomil, že moje zkušenosti s porozuměním fungování této architektury by mohly být prospěšné i pro ostatní. Proto píšu tento blogový příspěvek. Při psaní tohoto příspěvku jsem vlastně objevil a naučil se další věci, které mě při refaktoraci nenapadly.

## Aplikace
Aplikace, kterou budu refaktorovat, je [somewherexpress](https://github.com/NoryDev/somewherexpress), která umožňuje mým přátelům a mně organizovat vlastní soutěže v stopování a prezentovat výsledky. Výsledek si můžete prohlédnout zde.

Jedná se o poměrně standardní malou aplikaci Rails 4.2: má 8 modelů ActiveRecord + jejich příslušné řadiče a pohledy. Většinou se jedná o CRUD akce s několika triky, callbacky, vnořenými formuláři s [simple_form](https://github.com/heartcombo/simple_form), [devise](https://github.com/heartcombo/devise), [pundit](https://github.com/varvet/pundit) a transakčními e-maily. Žádné externě otevřené API.

## Trailblazer
Knihu Trailblazer lze zakoupit na [leanpub](https://leanpub.com/trailblazer). V tomto příspěvku budu odkazovat na pdf verzi knihy (pro čísla stránek).

Dvě úvodní kapitoly jsou velmi slibné:

> Trailblazer byl vytvořen při přepracování kódu Rails a absolutně nevyžaduje zelené pole s pasoucími se jednorožci a duhou. Je navržen tak, aby vám pomohl restrukturalizovat stávající monolitické aplikace, které jsou mimo kontrolu.
> — Trailblazer, str. 7

➡ To je zásadní

> Konvenční továrny v testech vytvářejí redundantní kód, který nikdy nevytvoří přesně stejný stav aplikace jako v produkci – což je zdrojem mnoha chyb. Zatímco testy mohou běžet dobře, produkce selhává, protože produkce nepoužívá továrny. V Trailblazeru jsou továrny nahrazeny operacemi.
> — Trailblazer, str. 7

➡ S továrnami nemám příliš mnoho problémů, ale to by byla dobrá výhoda

> Místo toho, aby se nechalo na programátorovi, jak navrhnout svůj „servisní objekt“, jaké rozhraní odhalit, jak strukturovat služby, Trailblazerova operace vám poskytuje dobře definovanou abstrakční vrstvu pro všechny druhy obchodní logiky.
> — Trailblazer, str. 17

➡ Skvělé, nechci se rozhodovat, dejte mi nějaké konvence

> Ačkoli je vykreslování dokumentů zajištěno fantastickými implementacemi, Rails podceňuje složitost ručního deserializování dokumentů. Mnoho vývojářů se spálilo při „rychlém vyplňování“ modelu zdroje z hash. Representers vás nutí přemýšlet v dokumentech, objektech a jejich transformacích – což je to, o čem API jsou.
> — Trailblazer, str. 30

➡ To by mohlo vyřešit hlavní potíže v mé každodenní práci s aplikacemi

## Refaktorování operace Create
Kniha doporučuje začít (nebo začít refaktorovat) s nejdůležitější obchodní akcí. V případě refaktorování nejsem k této radě skeptický. V jistém smyslu to chápu, je to vaše hlavní podnikání, chcete, aby fungovalo dobře. Ale je to pravděpodobně nejkomplexnější část vaší kódové základny. Takže začít refaktoringem obrovské metody může být náročné, když neznáte novou architekturu. I tak se tímto radou budu řídit. Pojďme tedy refaktorovat proces vytváření konkurence v somewherexpress. Tady je kód, který chci refaktorovat:

```ruby
# app/models/competition.rb
class Competition < ActiveRecord::Base
  has_many :tracks, dependent: :destroy
  # I want to get rid of this accepts_nested_attributes_for
  accepts_nested_attributes_for :tracks, allow_destroy: true

  belongs_to :start_city, class_name: "City", foreign_key: "start_city_id"
  belongs_to :end_city, class_name: "City", foreign_key: "end_city_id"

  has_many :tracks_start_cities, through: :tracks, source: :start_city
  has_many :tracks_end_cities, through: :tracks, source: :end_city

  # I want to get rid of these accepts_nested_attributes_for
  accepts_nested_attributes_for :start_city
  accepts_nested_attributes_for :end_city

  belongs_to :author, class_name: "User"

  # These validations should not be in the model
  validates :name, presence: true
  validates :start_registration, :start_city, :end_city,
            :start_date, :end_date, presence: { if: :published? }
  #[...]
end
```

```ruby
# app/models/track.rb
class Track < ActiveRecord::Base
  belongs_to :competition

  belongs_to :start_city, class_name: "City", foreign_key: "start_city_id"
  belongs_to :end_city, class_name: "City", foreign_key: "end_city_id"

  # I want to get rid of everything below this
  accepts_nested_attributes_for :start_city
  accepts_nested_attributes_for :end_city

  validates :start_city, :end_city, :start_time, presence: true
  #[...]
end
```

```ruby
# app/controllers/competitions_controller.rb
def create
  @competition = current_user.creations.new
  authorize @competition

  # I want to get rid of Competitions::Update, which is a big mess.
  # it's a kind of custom form object to map Cities based on their locality
  # attribute and not their id. The strong parameters lie in this class
  updater = Competitions::Update.new(@competition, params).call
  @competition = updater.competition
  @tracks = updater.updated_tracks

  if @competition.valid? && @tracks.map(&:valid?).all?
    send_new_competition_emails if @competition.published?

    redirect_to @competition
  else
    # This is a hack I also want to get rid of: the rendered form requires an
    # empty track that is removed on load with javascript
    track = Track.new(end_city: City.new, start_city: City.new)
    @tracks << track

    render :new
  end
end

private

  # This method should not be in the controller
  def send_new_competition_emails
    User.want_email_for_new_competition.each do |user|
      UserMailer.as_user_new_competition(user.id, @competition.id).deliver_later
    end
  end
```

Tento kus kódu obsahuje všechny obvyklé prvky a navíc několik výhod:

- podmíněné validace
- `accepts_nested_attributes_for` spojovací model
- zpětná volání
- vlastní služba (plnící funkci formulářového objektu), protože nechci, aby se při vytváření/aktualizaci spojovacího modelu (City) choval Rails standardním způsobem.
- některé zbytečné ozdoby, aby odpovídaly mému vykreslenému formuláři

Chci zkontrolovat, zda mohu refaktorovat pouze jednu část najednou. To je pro mě důležitý faktor. Jako první krok tedy chci refaktorovat:

- metodu `create` z `CompetitionsController`
- použít formulářový objekt k deserializaci a ověření dat pro vytvoření soutěže.

To je vše. Chci zachovat devise pro autentizaci, pundit pro autorizaci, zachovat své callbacky a vykreslovat své html pohledy. A právě v tomto bodě mi „pouhé následování“ knihy způsobilo velké potíže. Kniha je strukturována tak, aby demonstrovala, jak vytvořit aplikaci od nuly pomocí všech tříd Trailblazer. Pokud tedy chceme refaktorovat pouze jednu část, budeme muset přeskočit celé sekce.

Pojďme začít

### Trailblazer::Operation & Reform::Form
**Operace** je základní služba v Trailblazeru. Operace koordinuje veškerou obchodní logiku mezi dispečinkem řadiče a vrstvou perzistence.

Pokud prozatím ponecháme stranou autorizaci, chceme upravit `CompetitionsController#create` tak, aby vypadal takto:

```ruby
# app/controllers/competitions_controller.rb
def create
  run Competition::Create do |op|
    return redirect_to op.model
  end

  render action: :new
end
```

Jak je vysvětleno v knize Trailblazer na straně 49, pokud při spuštění operace nedojde k žádné výjimce, daný blok bude proveden, jinak ne. Tento způsob řešení chyb se mi líbí. Umožňuje vnoření služeb bez nutnosti mnoha vnořených podmínek. Pozor však, pokud operaci voláte pomocí syntaxe volání, výjimky nebudou zachyceny.

První věcí, kterou tedy potřebujeme, je nový soubor pro tuto operaci `Competition::Create`. Okamžitě integruji část **Contract** – vrstvu formulářového objektu, která používá [Reform](reform-cs.md), další skvost Trailblazeru – do operace.

Formulářový objekt je nejzajímavější částí této operace, takže prozatím odložme autorizaci a zpětné volání (odesílání e-mailů) a soustřeďme se na smlouvu. Pokud nemáte vnořené formuláře, je operace + smlouva podle knihy Trailblazer (kapitola 3) poměrně přímočará:

```ruby
RSpec.describe Competition::Create do
  it "creates an unpublished competition" do
    competition = Competition::Create
                    .(competition: { name: "new competition" })
                    .model

    expect(competition).to be_persisted
    expect(competition.name).to eq "new competition"
  end

  it "does not create an unpublished competition without name" do
    expect {
      Competition::Create.(competition: { name: "" })
    }.to raise_error Trailblazer::Operation::InvalidContract
  end
end
```

```ruby
# app/concepts/competition/operation.rb
class Competition < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include Model
    model Competition, :create

    # The contract is extracted into a new file, it's quickly going to be big.
    contract Contract::Create

    def process(params)
      validate(params[:competition]) do |form|
        form.save
      end
    end
  end
end
```

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      model :competition

      property :name
      # [...] more properties

      validates :name, presence: true
    end
  end
end
```

Pokud se řídím kapitolou 3 knihy, mám refaktorovat metodu „new“ (a její zobrazení) a poté pokračovat s aktualizací. To ale nechci dělat, dokud nebudu mít hotový formulářový objekt s vnořenými modely. A tady to začíná být složité.

### Vnořené formuláře: trvalé záznamy belongs_to
V knize Trailblazer musíme přejít ke kapitole 4 „Vnořené formuláře“, která začíná na straně 82.

Nejprve mám „autora“ soutěže, který musí být přiřazen k „current_user“. Dává mi smysl použít metodu „setup_model!“ (str. 85–86): uživatel není součástí formuláře, takže vztah s autorem lze řešit na úrovni operace. To znamená, že musím předat aktuálního uživatele do mé operace v parametrech:

```ruby
RSpec.describe Competition::Create do
  # [...]
  let!(:user) { FactoryGirl.create(:user) }

  it "creates a competition with author" do
    competition = Competition::Create
                  .call(competition: { name: "new competition" },
                        current_user: user)
                  .model

    expect(competition).to be_persisted
    expect(competition.author).to eq user
  end
end
```

```ruby
# app/controllers/competitions_controller.rb
def create
  run Competition::Create, 
      params: params.merge(current_user: current_user) do |op|
    return redirect_to op.model
  end

  render action: :new
end
```

```ruby
# app/concepts/competition/operation.rb
class Competition < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include Model
    model Competition, :create

    contract Contract::Create

    def process(params)
      validate(params[:competition]) do |form|
        form.save
      end
    end

    private

      def setup_model!(params)
        model.author = params[:current_user]
      end
  end
end
```

Soutěž také patří ke 2 městům, `start_city` a `end_city`, jejichž parametry jsou předány v požadavku. To znamená, že háček `setup_model!` není vhodný. Pokračováním ve čtení kapitoly 4 se dozvíme o možnosti `populate_if_empty` pro vnořené formuláře. K této možnosti můžeme předat metodu, což bude praktické pro nastavení našich měst.

V aplikaci somewherexpress jsou města neměnnými objekty. Ať už uživatel vytvoří nebo aktualizuje město, měl by se podívat do databáze, zda existuje město se stejným atributem `locality`, a pokud ano, nastavit jej jako odpovídající město (`start_city` nebo `end_city`). Pokud ne, vytvořit nové město s předanými parametry.

Zde je aktualizovaný test:

```ruby
RSpec.describe Competition::Create do
  # [...]
  let!(:user) { FactoryGirl.create(:user) }
  let!(:existing_city) do
    FactoryGirl.create(:city, locality: "Munich", name: "Munich, DE")
  end

  it "creates a published competition" do
    competition = Competition::Create
                  .call(competition: {
                          name: "new competition",
                          start_city: { name: "Yverdon, CH",
                                        locality: "Yverdon-Les-Bains",
                                        country_short: "CH" },
                          end_city: { name: "Munich, DE",
                                      locality: "Munich",
                                      country_short: "DE" }
                        },
                        current_user: user)
                  .model

    expect(competition).to be_persisted
    expect(competition.author).to eq user
    expect(competition.start_city.locality).to eq "Yverdon-Les-Bains"
    expect(competition.end_city.id).to eq existing_city.id
  end
end
```

Takto se smlouva vyvíjí:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      model :competition

      property :name
      # [...] more properties

      validates :name, presence: true

      property :start_city, populate_if_empty: :populate_city! do
        property :name
        property :locality
        property :country_short
        # [...] more properties

        validates :name, :locality, :country_short, presence: true
      end

      property :end_city, populate_if_empty: :populate_city! do
        property :name
        property :locality
        property :country_short
        # [...] more properties

        validates :name, :locality, :country_short, presence: true
      end

      private

        def populate_city!(options)
          # About this first return: it's a small hack. In my form view, I use
          # google places autcomplete. That means, when a name is entered,
          # a locality is set. But if the user erases the name, the locality
          # stays. The validation being ran only after populating, this first
          # return ensures that the form don't validate if the user erased the
          # name (but the locality stayed).
          return City.new unless options[:fragment].present? &&
                                 options[:fragment][:name].present?

          city = City.find_by(locality: options[:fragment][:locality])

          return city if city
          City.new(options[:fragment])
        end
    end
  end
end
```

A funguje to. Je to tak jednoduché. Jsem téměř šokován. Abychom si to ujasnili, dělat to se silnými parametry a bez deserializátoru ani formulářového objektu bylo velmi obtížné: Napsal jsem speciální službu `Competitions::Update`, 100 řádků kódu, aby se nastavilo správné `start_city`, `end_city` (a, jak uvidíme později, trasy každé soutěže `start_city` a `end_city`). Byl to kompletní hack, který selhával v okrajových případech.

Teď je to tak příjemné a čisté. I kdyby jediným přínosem byla tato část, stálo by za to použít Reform!

Jak vidíme, vlastnosti obou měst jsou stejné. Můžeme tento kód extrahovat do vlastního formuláře, aby byl čistší:

```ruby
# app/concepts/city/form.rb
class City < ActiveRecord::Base
  class Form < Reform::Form
    property :name
    property :locality
    property :country_short
    # [...] more properties

    validates :name, :locality, :country_short, presence: true
  end
end
```

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      property :start_city, populate_if_empty: :populate_city!,
                            form: City::Form

      property :end_city, populate_if_empty: :populate_city!,
                          form: City::Form
      # [...]
    end
  end
end
```

Nakonec mohu představit své druhé ověření týkající se konkurence, které zní takto:

```ruby
validates :start_registration, :start_city, :end_city,
          :start_date, :end_date, presence: { if: :published? }
```

```ruby
RSpec.describe Competition::Create do
  # [...]
  let!(:user) { FactoryGirl.create(:user) }
  let!(:existing_city) do
    FactoryGirl.create(:city, locality: "Munich", name: "Munich, DE")
  end

  it "creates a published competition" do
    competition = Competition::Create
                  .call(competition: {
                          name: "new competition",
                          published: "1",
                          start_date: 2.weeks.from_now.to_s,
                          end_date: 3.weeks.from_now.to_s,
                          start_registration: Time.current,
                          start_city: { name: "Yverdon, CH",
                                        locality: "Yverdon-Les-Bains",
                                        country_short: "CH" },
                          end_city: { name: "Munich, DE",
                                      locality: "Munich",
                                      country_short: "DE" }
                        },
                        current_user: user)
                  .model

    expect(competition).to be_persisted
    expect(competition.author).to eq user
    expect(competition.start_city.locality).to eq "Yverdon-Les-Bains"
    expect(competition.end_city.id).to eq existing_city.id
  end
end
```

Trik spočívá v části `if: :published?`. Třídy Reform neznají kouzla modelů Rails, takže musíme explicitně definovat `published?`. V tomto ohledu mi velmi pomohla tato stránka dokumentace Reform:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      property :name
      property :start_date
      property :end_date
      property :start_registration
      property :published

      property :start_city, populate_if_empty: :populate_city!,
                            form: City::Form

      property :end_city, populate_if_empty: :populate_city!,
                          form: City::Form

      validates :name, presence: true
      validates :start_registration, :start_city, :end_city,
                :start_date, :end_date, presence: { if: :published? }
      # [...]

    private

      def published?
        published && published != "0"
      end

      # [...]
    end
  end
end
```

A to je vše, jsme připraveni na ověřování na úrovni soutěže a vnořené modely typu belongs_to.

### Vnořené formuláře: trvalé záznamy has_many
Soutěž má mnoho tratí a tratě se vytvářejí a aktualizují ve formuláři soutěže. Uživatel může z formuláře odstranit trať. Tím se odešle požadavek na odstranění do `TracksController#destroy`, takže se zde nemusíme zabývat odstraněnými tratěmi. Tratě mají také 2 vnořená města, stejně jako soutěž. Jsou vyplňovány stejným způsobem.

Nyní musíme implementovat vlastnosti těchto vnořených tratí do naší smlouvy. Zbytek kapitoly 4 knihy Trailblazer nám příliš nepomůže, protože se zabývá hlavně vykreslováním formuláře. Musíme přejít ke kapitole 5 „Mastering Forms“ (Zvládnutí formulářů), která začíná na straně 128.

```ruby
RSpec.describe Competition::Create do
  # [...]
  let!(:user) { FactoryGirl.create(:user) }
  let!(:existing_city) do
    FactoryGirl.create(:city, locality: "Munich", name: "Munich, DE")
  end

  it "creates a published competition" do
    competition = Competition::Create
                  .call(competition: {
                          name: "new competition",
                          published: "1",
                          start_date: 2.weeks.from_now.to_s,
                          end_date: 3.weeks.from_now.to_s,
                          start_registration: Time.current,
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

    expect(competition).to be_persisted
    expect(competition.author).to eq user
    expect(competition.start_city.locality).to eq "Yverdon-Les-Bains"
    expect(competition.tracks.size).to eq 1
    expect(competition.tracks.first.end_city.id).to eq existing_city.id
    expect(competition.end_city.id).to eq existing_city.id
  end
end
```

Pro vnořené vztahy typu `has_many` můžeme použít kolekci:

```ruby
# app/concepts/competition/contract.rb
class Competition < ActiveRecord::Base
  module Contract
    class Create < Reform::Form
      # [...]
      collection :tracks, populate_if_empty: :populate_track! do

        property :start_time

        property :start_city, populate_if_empty: :populate_city!,
                              form: City::Form

        property :end_city, populate_if_empty: :populate_city!,
                            form: City::Form

        validates :start_city, :end_city, :start_time, presence: true

        private

          def populate_city!(options)
            return City.new unless options[:fragment].present? &&
                                   options[:fragment][:name].present?

            city = City.find_by(locality: options[:fragment][:locality])

            return city if city
            City.new(options[:fragment])
          end
      end

      private

        def populate_track!(options)
          Track.new(start_time: options[:fragment][:start_time])
        end

      # [...]
    end
  end
end
```

A to je v podstatě vše, co chceme, pokud jde o uchovávání příchozích dat.

### Vraťte autorizaci a zpětné volání
Jak jsem již řekl, chci provést minimální refaktorizaci, tedy objekt formuláře. Vraťme tedy autorizační metodu (používám pundit) a zpětné volání (odesílání e-mailu) do původního stavu.

Pro autorizaci metoda `authorize` punditu očekává buď instanci soutěže, nebo samotnou třídu Competition. V `CompetitionsController#create` už nemám žádnou instanci soutěže. Moje politika nezávisí na záznamu soutěže, ale pouze na aktuálním uživateli. To znamená, že mohu předat třídu Competition k autorizaci:

```ruby
# app/policies/competition_policy.rb
class CompetitionPolicy < ApplicationPolicy
  # [....]
  def create?
    user && (user.organizer || user.admin)
  end
end
```

```ruby
# app/controllers/competitions_controller.rb
def create
  authorize Competition
  # [...]
end
```

Pokud jde o zpětné volání, mohu jednoduše přesunout vše do operace:

```ruby
class Competition < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include Model
    model Competition, :create

    contract Contract::Create

    def process(params)
      validate(params[:competition]) do |form|
        form.save

        # This #published? will work: it's called on the AR model, which
        # understands this method call (unlike the form object)
        send_new_competition_emails if model.published?
      end
    end

    private

      def send_new_competition_emails
        User.want_email_for_new_competition.each do |user|
          UserMailer.as_user_new_competition(user.id, model.id).deliver_later
        end
      end

      # [...]
  end
```

Zpětné volání je stále problematické: e-maily budou odesílány při každém volání operace. Ale to je problém na jindy.

Stále máme problém v `CompetitionsController#create`: pokud formulář neprojde validací, musíme vykreslit `new`. Ale `new` vyžaduje objekt `@competition`, který už nemáme. Mohli bychom to obejít tak, že předáme formulář jako `@competition`.

V případě aplikace somewherexpress by to vyžadovalo několik úprav rozvržení a pomocníků, ale ne tolik. Tyto změny ukážu, až budeme refaktorovat vykreslování formuláře. Chci tím jen říct, že je to proveditelné, aniž by došlo k narušení hlavní struktury zobrazení. Toto by byla naše konečná metoda kontroléru:
```ruby
def create
  authorize Competition
  operation = run Competition::Create,
                  params: params.merge(current_user: current_user) do |op|
    return redirect_to op.model
  end

  @competition = operation.contract
  render action: :new
end
```

A je to! Přesunuli jsme trvalé chování Competition do tříd Trailblazer! A udělali jsme to bez nutnosti refaktorovat celou aplikaci nebo dokonce celý kontrolér.

Za to vám dávám 👍👍 Trailblazer, splnil jste slib, že „můžete refaktorovat jen některé části“.

[Přejít na část 2](journey-02-cs.md)