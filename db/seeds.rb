# Seed data so that a freshly booted API is worth calling.
#
# Idempotent: every record is looked up before it is created, so `db:seed` can
# be run repeatedly (the Docker entrypoint runs it on every boot).

author_data = [
  {
    first_name: 'Ursula',
    last_name: 'Le Guin',
    website: 'https://www.ursulakleguin.com',
    genres: %w[science-fiction fantasy],
    description: 'Author of the Earthsea cycle and the Hainish novels.'
  },
  {
    first_name: 'Terry',
    last_name: 'Pratchett',
    website: 'https://www.terrypratchettbooks.com',
    genres: %w[fantasy satire],
    description: 'Author of the Discworld series.'
  },
  {
    first_name: 'Octavia',
    last_name: 'Butler',
    website: nil,
    genres: %w[science-fiction afrofuturism],
    description: 'Author of the Patternist and Parable series.'
  }
].freeze

book_data = [
  { author: 'Le Guin', title: 'A Wizard of Earthsea', publish_date: '1968-11-01',
    description: 'A young mage learns his true name, and what it costs.' },
  { author: 'Le Guin', title: 'The Left Hand of Darkness', publish_date: '1969-03-01',
    description: 'An envoy on a world without fixed gender.' },
  { author: 'Pratchett', title: 'Guards! Guards!', publish_date: '1989-11-10',
    description: 'The Night Watch acquires a dragon problem.' },
  { author: 'Pratchett', title: 'Small Gods', publish_date: '1992-05-01',
    description: 'A great god finds himself reduced to a tortoise.' },
  { author: 'Butler', title: 'Kindred', publish_date: '1979-06-01',
    description: 'A woman is pulled between 1976 California and an antebellum plantation.' },
  { author: 'Butler', title: 'Parable of the Sower', publish_date: '1993-10-01',
    description: 'A hyperempathic teenager walks north through a collapsing California.' }
].freeze

user_data = [
  %w[Ada Lovelace], %w[Grace Hopper], %w[Alan Turing],
  %w[Katherine Johnson], %w[Barbara Liskov]
].freeze

# title, reviewer, rating, description (nil exercises the description_only filter)
book_review_data = [
  ['A Wizard of Earthsea', 'Ada', 5, 'Spare, patient and completely assured.'],
  ['A Wizard of Earthsea', 'Grace', 4, nil],
  ['A Wizard of Earthsea', 'Alan', 5, 'The shadow chase still lands.'],
  ['The Left Hand of Darkness', 'Ada', 5, 'The ice crossing is the best hundred pages here.'],
  ['The Left Hand of Darkness', 'Katherine', 3, 'Admirable, but slow to start.'],
  ['Guards! Guards!', 'Grace', 5, 'Funny and, underneath, quite angry.'],
  ['Guards! Guards!', 'Barbara', 4, nil],
  ['Guards! Guards!', 'Alan', 4, 'Vimes is the best thing Pratchett wrote.'],
  ['Small Gods', 'Ada', 4, 'A theology lecture disguised as a comedy.'],
  ['Kindred', 'Katherine', 5, 'Unsparing. I read it in one sitting.'],
  ['Kindred', 'Barbara', 5, 'The time travel is a device; the history is the point.'],
  ['Parable of the Sower', 'Alan', 4, 'Uncomfortably plausible.'],
  ['Parable of the Sower', 'Grace', 3, nil]
].freeze

# Reviews of the authors themselves, which is a stretch goal of the brief.
author_review_data = [
  ['Le Guin', 'Ada', 5, 'Never wrote a careless sentence.'],
  ['Pratchett', 'Barbara', 5, 'Prolific without ever coasting.'],
  ['Butler', 'Alan', 5, nil]
].freeze

ActiveRecord::Base.transaction do
  authors = author_data.each_with_object({}) do |attributes, acc|
    author = Author.find_or_initialize_by(
      first_name: attributes[:first_name],
      last_name: attributes[:last_name]
    )
    author.update!(attributes)
    acc[attributes[:last_name]] = author
  end

  books = book_data.each_with_object({}) do |attributes, acc|
    book = Book.find_or_initialize_by(title: attributes[:title])
    book.update!(attributes.except(:author).merge(author: authors.fetch(attributes[:author])))
    acc[attributes[:title]] = book
  end

  users = user_data.each_with_object({}) do |(first_name, last_name), acc|
    acc[first_name] = User.find_or_create_by!(first_name: first_name, last_name: last_name)
  end

  reviews = book_review_data.map { |title, *rest| [books.fetch(title), *rest] } +
            author_review_data.map { |name, *rest| [authors.fetch(name), *rest] }

  reviews.each do |reviewable, reviewer, rating, description|
    review = Review.find_or_initialize_by(reviewable: reviewable, user: users.fetch(reviewer))
    review.update!(rating: rating, description: description)
  end

  # The counters are maintained by callbacks, but seeding is exactly the kind
  # of bulk path where it is worth proving they agree with the source data.
  RefreshBookRating.recalculate!
end

puts "Seeded #{Author.count} authors, #{Book.count} books, " \
     "#{User.count} users and #{Review.count} reviews."
