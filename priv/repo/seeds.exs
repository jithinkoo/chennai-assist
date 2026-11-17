# Script for populating the database. Run with:
#
#     mix run priv/repo/seeds.exs
#
# It is safe to run more than once: guides are matched by slug and the
# admin account by email.

alias ChennaiAssist.Repo
alias ChennaiAssist.Content.{Guide, Interview}
alias ChennaiAssist.Accounts

# --- Admin account -----------------------------------------------------------
# Set ADMIN_EMAIL and ADMIN_PASSWORD (12+ characters) before running seeds.
# ADMIN_PASSWORD is the source of truth: if the admin already exists with a
# different password, it is reset to ADMIN_PASSWORD (and old logins end).
trimmed = fn name ->
  case System.get_env(name) do
    nil -> nil
    value -> if String.trim(value) == "", do: nil, else: String.trim(value)
  end
end

admin_email = trimmed.("ADMIN_EMAIL")
admin_password = trimmed.("ADMIN_PASSWORD")

cond do
  is_nil(admin_email) or is_nil(admin_password) ->
    IO.puts("Admin: ADMIN_EMAIL / ADMIN_PASSWORD not set, so no admin account was created")

  String.length(admin_password) < 12 ->
    IO.puts("Admin: ADMIN_PASSWORD is shorter than 12 characters, so the admin was not created/updated")

  user = Accounts.get_user_by_email(admin_email) ->
    if Accounts.User.valid_password?(user, admin_password) do
      IO.puts("Admin: #{admin_email} ready")
    else
      user
      |> Accounts.User.password_changeset(%{password: admin_password})
      |> Repo.update!()

      Repo.delete_all(Accounts.UserToken.by_user_and_contexts_query(user, :all))
      IO.puts("Admin: password for #{admin_email} reset to ADMIN_PASSWORD")
    end

  true ->
    case Accounts.register_user(%{email: admin_email, password: admin_password}) do
      {:ok, _} -> IO.puts("Admin: created #{admin_email}")
      {:error, cs} -> IO.puts("Admin: not created: #{inspect(cs.errors)}")
    end
end

# --- City guide ---------------------------------------------------------------
guides = [
  %{
    slug: "moving-to-chennai",
    category: "moving",
    title: "Moving to Chennai: your first 30 days",
    summary: "A checklist for the first month: where to stay, SIM, transport, documents and settling in.",
    body: """
    Welcome to Chennai (Madras). The first month is the hardest, so here is a simple order of things.

    Week 1: Stay short-term first
    Book a service apartment, PG (paying guest) or hostel near your office for 2-4 weeks. Do not pay a large rental advance before you have seen the area at night, in the rain and at peak traffic hour.

    Week 1: Phone and money
    Get a local SIM (Jio, Airtel, Vi) with your ID and photo. UPI (GPay, PhonePe, Paytm) is used everywhere, from tea shops to autos, so set it up early.

    Week 2: Learn the commute
    Try your office route by Metro, bus, suburban train and auto before choosing a house. A 10 km trip can take 25 minutes or 75 minutes depending on the road.

    Week 2-3: Find a house
    Read our Rent and Areas guide. Visit at least 3 places. Check water supply, power backup, parking and whether the street floods.

    Week 4: Paperwork
    Rental agreement (registered or on stamp paper), address proof update, gas connection, and a local doctor and pharmacy near you.

    Ask us anything through the live chat. That is what this help desk is for.
    """
  },
  %{
    slug: "rent-and-areas",
    category: "rent",
    title: "Rent, advance and choosing an area",
    summary: "How renting works in Chennai, the big advance deposit, and which areas suit which life.",
    body: """
    How renting works
    Chennai landlords usually ask for a large security advance, often several months of rent (5 to 10 months is common, some accept less). It is refundable when you leave, minus damages and painting. Negotiate it. Brokers usually charge around one month's rent.

    Rough monthly rent ranges (2026, unfurnished, varies a lot by building)
    - 1 BHK: about Rs 10,000 to Rs 22,000
    - 2 BHK: about Rs 16,000 to Rs 40,000
    - Central, premium areas (Adyar, Alwarpet, Nungambakkam, Besant Nagar) cost more.
    Always check current listings (NoBroker, MagicBricks, 99acres, local brokers); these are guide figures, not quotes.

    Areas by lifestyle
    - IT corridor (OMR, Sholinganallur, Perungudi, Thoraipakkam, Siruseri): close to tech parks, newer apartments, heavy traffic at peak hours.
    - South, family and beach (Adyar, Besant Nagar, Thiruvanmiyur): green, calm, more expensive.
    - Old Chennai culture (Mylapore, T. Nagar, Triplicane): temples, shopping, food, crowded streets.
    - West and north-west (Anna Nagar, Vadapalani, Porur, Valasaravakkam): good for families, well connected.
    - Budget south (Tambaram, Chromepet, Medavakkam, Pallavaram): cheaper, suburban trains, longer commutes.

    Checklist before you pay
    - Water: Metro water, borewell or tanker? Taste it. Ask about summer shortages.
    - Flooding: ask neighbours what happened in the last heavy monsoon. Some low-lying pockets flood every year.
    - Power backup, lift, parking, and who pays maintenance.
    - Get a written agreement with the advance amount and refund terms.
    """
  },
  %{
    slug: "autos-metro-buses",
    category: "transport",
    title: "Getting around: autos, Metro, buses and trains",
    summary: "How to use autos without overpaying, plus Metro, MTC buses and suburban trains.",
    body: """
    Autos
    Auto-rickshaws are everywhere. Many drivers quote a fixed price instead of using the meter. Tips:
    - Book through an app (Namma Yatri, Rapido, Uber, Ola) to see a fair price first.
    - If hailing on the street, agree the price before you sit down.
    - Night fares are higher. Keep small change or use UPI.

    Chennai Metro
    Clean, air-conditioned and the fastest way across the city on its routes (the Blue line via the airport and Anna Salai, the Green line via Central and Koyambedu). Phase 2 lines are being built, so expect road works near construction sites. Use the CMRL app or a travel card.

    MTC buses
    The cheapest way around, with a huge network. Some buses are free for women. Use the Chennai Bus app or Google Maps for routes.

    Suburban and MRTS trains
    The Beach-Tambaram line and the MRTS (Beach-Velachery) are very cheap and avoid traffic. Very crowded at peak hours; there are ladies' compartments.

    Bike taxis and cabs
    Rapido and Uber Moto are quick in traffic. Cabs are comfortable for the airport and late nights.
    """
  },
  %{
    slug: "weather-and-monsoon",
    category: "weather",
    title: "Weather: heat, humidity and the monsoon",
    summary: "Chennai is hot most of the year; the big rains come October to December.",
    body: """
    The short version: hot, humid, then very wet.

    - March to June: hottest months, often 35 to 42 C in May with high humidity. Stay hydrated, avoid the midday sun, and choose a house with good ventilation.
    - June to September: still hot, with some evening showers. Chennai gets less rain from the south-west monsoon than the rest of India.
    - October to December: the north-east monsoon. This is Chennai's main rainy season. Heavy rain, waterlogging in low-lying areas, and sometimes cyclones from the Bay of Bengal.
    - January and February: the most pleasant months. Warm days, slightly cool mornings.

    Monsoon tips
    - Follow official weather alerts (IMD Chennai) and local news.
    - Keep phones charged, some cash and drinking water during cyclone warnings.
    - Park vehicles on high ground when heavy rain is forecast.
    - Cotton clothes, an umbrella and sandals are your best friends all year.
    """
  },
  %{
    slug: "food-guide",
    category: "food",
    title: "Food: from idli to biryani",
    summary: "What to eat, where locals go, and filter coffee etiquette.",
    body: """
    Breakfast is serious business
    Idli, dosa, pongal, vada and sambar, with filter coffee. Try a classic "mess" or tiffin centre for the real experience; meals are often served on a banana leaf.

    Must-try
    - Filter coffee (strong, milky, served in a tumbler and dabara)
    - Meals: rice with sambar, rasam, kootu, poriyal and curd, often unlimited at lunch
    - Chettinad cuisine: spicy, aromatic chicken and mutton dishes
    - Biryani: Chennai loves it, from the Ambur and Dindigul styles to local favourites
    - Street food: bajji, sundal at the beach, kothu parotta at night, atho in north Chennai

    Where to explore
    Mylapore and T. Nagar for traditional vegetarian food, Royapettah and Triplicane for biryani and late-night eats, Besant Nagar and ECR for cafes, Sowcarpet for North Indian sweets and chaat.

    Eating with your hand (right hand) is normal and welcome. Vegetarian options are everywhere.
    """
  },
  %{
    slug: "culture-and-festivals",
    category: "culture",
    title: "Culture, festivals and etiquette",
    summary: "Tamil language, temples, music season and how to fit in.",
    body: """
    Chennai is proud of its Tamil language, its classical arts and its cinema.

    Festivals
    - Pongal (mid-January): the harvest festival and Tamil Nadu's biggest celebration. Many people travel home.
    - Tamil New Year (mid-April), Deepavali (October/November), Vinayagar Chathurthi, Christmas and Eid are all widely celebrated.
    - The Margazhi music and dance season (December to January): hundreds of Carnatic music and Bharatanatyam concerts in sabhas, many of them free.

    Places that show the city's soul
    Kapaleeshwarar Temple in Mylapore, Marina Beach at sunrise, Santhome Cathedral, Fort St. George, the Government Museum in Egmore, and Mahabalipuram (a day trip down ECR).

    Etiquette
    - Remove footwear before entering temples and many homes.
    - Dress modestly at religious places.
    - Use "Anna" (elder brother) or "Akka" (elder sister) to address people politely.
    - A little Tamil goes a long way: Vanakkam (hello), Nandri (thank you), Evlo? (how much?), Podhum (enough).
    """
  },
  %{
    slug: "people-and-language",
    category: "people",
    title: "The people: friendly, direct, and proud of Tamil",
    summary: "What locals are like, and how to make friends fast.",
    body: """
    Chennai people are warm once you know them, helpful in emergencies, and direct. The city is more conservative than Bengaluru or Mumbai in some ways, but very welcoming of newcomers. Lakhs of people from across India work here.

    Language
    Tamil is the everyday language. In IT parks, malls and offices English works well. With auto drivers, small shops and older neighbours, a few Tamil words help a lot, and people appreciate the effort. Hindi is understood by some, but do not assume it.

    Making friends
    - Join a running club at Besant Nagar or Marina, a weekend trek group, or a quiz or theatre group.
    - Cricket (the local IPL team is hugely popular) and Tamil cinema are instant conversation starters.
    - Food invitations are common. Accept, and try a bit of everything.
    """
  },
  %{
    slug: "politics-explained",
    category: "politics",
    title: "Politics in Tamil Nadu, explained simply",
    summary: "The Dravidian movement, the main parties and why it matters to daily life.",
    body: """
    This is a neutral, simple explainer. We do not support any party.

    The background
    Tamil Nadu politics has been shaped since the 1960s by the Dravidian movement, which focuses on social justice, Tamil identity and language, and state rights. Two Dravidian parties, the DMK and the AIADMK, have led the state government for decades, usually in alliances with smaller parties. National parties and newer parties, including ones started by film stars, also compete.

    Why it matters to you
    - Welfare schemes (such as free bus travel for women, breakfast schemes in schools and rationing) come from state policy.
    - Language policy: Tamil and English are central; Hindi imposition is a sensitive topic.
    - Rallies and bandhs can affect traffic on some days.

    Tips
    - Politics and cinema are closely linked here; fans are passionate.
    - Avoid heated political arguments with people you have just met.
    - For the current government and recent election results, check up-to-date news sources.
    """
  }
]

for attrs <- guides do
  case Repo.get_by(Guide, slug: attrs.slug) do
    nil -> Repo.insert!(Guide.changeset(%Guide{}, Map.put(attrs, :published, true)))
    _existing -> :ok
  end
end

# --- Sample interview ----------------------------------------------------------
unless Repo.get_by(Interview, slug: "sample-mylapore-interview") do
  Repo.insert!(
    Interview.changeset(%Interview{}, %{
      slug: "sample-mylapore-interview",
      title: "Sample: what is it like to live in Mylapore?",
      person_name: "Sample resident",
      occupation: "Replace with your interviewee",
      area: "Mylapore",
      published: false,
      body: """
      This is a sample interview layout. Edit it from the admin screen, or delete it and post your own.

      Q: How long have you lived here?
      A: ...

      Q: What should a newcomer know about this area?
      A: ...
      """
    })
  )
end
