# Captured output

Every block on this page is real output from the stack that
`docker compose up --build` starts, captured against the seed
data in `db/seeds.rb` (Ruby 3.4.12, Rails 8.1, Puma 8, Postgres 17). This API
has no user interface, so there are no screenshots: these transcripts are the
equivalent.

Responses are piped through `jq` for readability, and only the paging headers
are shown. The requests run in the order listed, so the review created part way
down is visible in the later responses.

## Booting the stack

```console
$ docker compose up --build
api-1  | ==> waiting for the database
api-1  | ==> preparing the database
api-1  | Seeded 3 authors, 6 books, 5 users and 16 reviews.
api-1  | Puma starting in single mode...
api-1  | * Puma version: 8.0.2 ("Into the Arena")
api-1  | * Ruby version: ruby 3.4.12 (2026-10-23 revision 366f5fdc00) +PRISM [aarch64-linux]
api-1  | *  Min threads: 5
api-1  | *  Max threads: 5
api-1  | *  Environment: production
api-1  | *          PID: 1
api-1  | * Listening on http://0.0.0.0:3000
api-1  | Use Ctrl-C to stop
```

The entrypoint waits for Postgres and runs `db:prepare`, which creates, loads
and seeds an empty database (and only migrates an existing one), before Puma
starts. The first request already has data behind it.

## Requests and responses

### Health probe

```console
$ curl -i http://localhost:8150/health
HTTP/1.1 200 OK

{
  "status": "ok",
  "database": "ok"
}
```

### List books (paginated, with the paging headers)

```console
$ curl -i 'http://localhost:8150/api/books?per_page=3'
HTTP/1.1 200 OK
x-page: 1
x-per-page: 3
x-total-count: 6
x-total-pages: 2

[
  {
    "id": 1,
    "title": "A Wizard of Earthsea",
    "description": "A young mage learns his true name, and what it costs.",
    "publish_date": "1968-11-01",
    "rating": 4.67,
    "ratings_count": 3,
    "author_id": 1,
    "created_at": "2026-11-07T23:15:26.476Z",
    "updated_at": "2026-11-07T23:15:26.476Z"
  },
  {
    "id": 2,
    "title": "The Left Hand of Darkness",
    "description": "An envoy on a world without fixed gender.",
    "publish_date": "1969-03-01",
    "rating": 4.0,
    "ratings_count": 2,
    "author_id": 1,
    "created_at": "2026-11-07T23:15:26.491Z",
    "updated_at": "2026-11-07T23:15:26.491Z"
  },
  {
    "id": 3,
    "title": "Guards! Guards!",
    "description": "The Night Watch acquires a dragon problem.",
    "publish_date": "1989-11-10",
    "rating": 4.33,
    "ratings_count": 3,
    "author_id": 2,
    "created_at": "2026-11-07T23:15:26.495Z",
    "updated_at": "2026-11-07T23:15:26.495Z"
  }
]
```

### One book

```console
$ curl http://localhost:8150/api/books/1
{
  "id": 1,
  "title": "A Wizard of Earthsea",
  "description": "A young mage learns his true name, and what it costs.",
  "publish_date": "1968-11-01",
  "rating": 4.67,
  "ratings_count": 3,
  "author_id": 1,
  "created_at": "2026-11-07T23:15:26.476Z",
  "updated_at": "2026-11-07T23:15:26.476Z"
}
```

### A book's reviews, sorted by rating, highest first

```console
$ curl -i 'http://localhost:8150/api/books/1/reviews?sort_by=rating&order=desc'
HTTP/1.1 200 OK
x-page: 1
x-per-page: 25
x-total-count: 3
x-total-pages: 1

{
  "reviews": [
    {
      "id": 1,
      "rating": 5,
      "description": "Spare, patient and completely assured.",
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 1,
      "user": {
        "id": 1,
        "first_name": "Ada",
        "last_name": "Lovelace"
      },
      "created_at": "2026-11-07T23:15:26.599Z",
      "updated_at": "2026-11-07T23:15:26.599Z"
    },
    {
      "id": 3,
      "rating": 5,
      "description": "The shadow chase still lands.",
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 3,
      "user": {
        "id": 3,
        "first_name": "Alan",
        "last_name": "Turing"
      },
      "created_at": "2026-11-07T23:15:26.628Z",
      "updated_at": "2026-11-07T23:15:26.628Z"
    },
    {
      "id": 2,
      "rating": 4,
      "description": null,
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 2,
      "user": {
        "id": 2,
        "first_name": "Grace",
        "last_name": "Hopper"
      },
      "created_at": "2026-11-07T23:15:26.624Z",
      "updated_at": "2026-11-07T23:15:26.624Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 3,
    "total_pages": 1
  }
}
```

### Filtering: only four-star reviews that have a description

```console
$ curl -i 'http://localhost:8150/api/books/3/reviews?description_only=true&rating=4'
HTTP/1.1 200 OK
x-page: 1
x-per-page: 25
x-total-count: 1
x-total-pages: 1

{
  "reviews": [
    {
      "id": 8,
      "rating": 4,
      "description": "Vimes is the best thing Pratchett wrote.",
      "reviewable_type": "Book",
      "reviewable_id": 3,
      "user_id": 3,
      "user": {
        "id": 3,
        "first_name": "Alan",
        "last_name": "Turing"
      },
      "created_at": "2026-11-07T23:15:26.655Z",
      "updated_at": "2026-11-07T23:15:26.655Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 1,
    "total_pages": 1
  }
}
```

### Paging through a book's reviews

```console
$ curl -i 'http://localhost:8150/api/books/1/reviews?page=2&per_page=2'
HTTP/1.1 200 OK
x-page: 2
x-per-page: 2
x-total-count: 3
x-total-pages: 2

{
  "reviews": [
    {
      "id": 3,
      "rating": 5,
      "description": "The shadow chase still lands.",
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 3,
      "user": {
        "id": 3,
        "first_name": "Alan",
        "last_name": "Turing"
      },
      "created_at": "2026-11-07T23:15:26.628Z",
      "updated_at": "2026-11-07T23:15:26.628Z"
    }
  ],
  "meta": {
    "page": 2,
    "per_page": 2,
    "total": 3,
    "total_pages": 2
  }
}
```

### Reviews of an author (stretch goal)

```console
$ curl -i http://localhost:8150/api/authors/1/reviews
HTTP/1.1 200 OK
x-page: 1
x-per-page: 25
x-total-count: 1
x-total-pages: 1

{
  "reviews": [
    {
      "id": 14,
      "rating": 5,
      "description": "Never wrote a careless sentence.",
      "reviewable_type": "Author",
      "reviewable_id": 1,
      "user_id": 1,
      "user": {
        "id": 1,
        "first_name": "Ada",
        "last_name": "Lovelace"
      },
      "created_at": "2026-11-07T23:15:26.680Z",
      "updated_at": "2026-11-07T23:15:26.680Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 1,
    "total_pages": 1
  }
}
```

### A book before it is reviewed again

```console
$ curl http://localhost:8150/api/books/4
{
  "id": 4,
  "title": "Small Gods",
  "description": "A great god finds himself reduced to a tortoise.",
  "publish_date": "1992-05-01",
  "rating": 4.0,
  "ratings_count": 1,
  "author_id": 2,
  "created_at": "2026-11-07T23:15:26.498Z",
  "updated_at": "2026-11-07T23:15:26.498Z"
}
```

### Creating a review

```console
$ curl -i -X POST http://localhost:8150/api/books/4/reviews -H 'Content-Type: application/json' -d '{"user_id":2,"rating":2,"description":"Not for me."}'
HTTP/1.1 201 Created

{
  "message": "success"
}
```

### The same book afterwards: the average was updated by the write

```console
$ curl http://localhost:8150/api/books/4
{
  "id": 4,
  "title": "Small Gods",
  "description": "A great god finds himself reduced to a tortoise.",
  "publish_date": "1992-05-01",
  "rating": 3.0,
  "ratings_count": 2,
  "author_id": 2,
  "created_at": "2026-11-07T23:15:26.498Z",
  "updated_at": "2026-11-07T23:15:26.498Z"
}
```

### A second review from the same user is rejected

```console
$ curl -i -X POST http://localhost:8150/api/books/4/reviews -H 'Content-Type: application/json' -d '{"user_id":2,"rating":5}'
HTTP/1.1 422 Unprocessable Content

{
  "errors": [
    "Reviewable can't post multiple reviews"
  ]
}
```

### A rating outside 1-5 is rejected

```console
$ curl -i -X POST http://localhost:8150/api/books/5/reviews -H 'Content-Type: application/json' -d '{"user_id":1,"rating":9}'
HTTP/1.1 422 Unprocessable Content

{
  "errors": [
    "Rating rating should be in range of 1..5"
  ]
}
```

### A fractional rating is rejected, not truncated

```console
$ curl -i -X POST http://localhost:8150/api/books/5/reviews -H 'Content-Type: application/json' -d '{"user_id":1,"rating":4.5}'
HTTP/1.1 422 Unprocessable Content

{
  "errors": [
    "Rating must be an integer"
  ]
}
```

### The profanity filter

```console
$ curl -i -X POST http://localhost:8150/api/books/5/reviews -H 'Content-Type: application/json' -d '{"user_id":1,"rating":3,"description":"What a load of gorram nonsense."}'
HTTP/1.1 422 Unprocessable Content

{
  "errors": [
    "Description cannot contain fictional profanity"
  ]
}
```

### A client-supplied rating on a book is ignored

```console
$ curl -i -X PATCH http://localhost:8150/api/books/1 -H 'Content-Type: application/json' -d '{"rating":5,"description":"A young mage learns his true name, and what it costs."}'
HTTP/1.1 200 OK

{
  "id": 1,
  "title": "A Wizard of Earthsea",
  "description": "A young mage learns his true name, and what it costs.",
  "publish_date": "1968-11-01",
  "rating": 4.67,
  "ratings_count": 3,
  "author_id": 1,
  "created_at": "2026-11-07T23:15:26.476Z",
  "updated_at": "2026-11-07T23:15:26.476Z"
}
```

### A publish_date that does not parse is rejected

```console
$ curl -i -X PATCH http://localhost:8150/api/books/2 -H 'Content-Type: application/json' -d '{"publish_date":"soon"}'
HTTP/1.1 422 Unprocessable Content

{
  "errors": [
    "Publish date is not a valid date"
  ]
}
```

### A malformed JSON body gets the same error envelope

```console
$ curl -i -X POST http://localhost:8150/api/users -H 'Content-Type: application/json' -d '{"first_name":"Ada",'
HTTP/1.1 400 Bad Request

{
  "errors": [
    "Request body is not valid JSON"
  ]
}
```

### An unknown book is a 404, not an empty list

```console
$ curl -i http://localhost:8150/api/books/999999/reviews
HTTP/1.1 404 Not Found

{
  "errors": [
    "Resource not found"
  ]
}
```

### Hostile paging parameters are clamped, not rejected

```console
$ curl -i 'http://localhost:8150/api/books?page=-3&per_page=100000'
HTTP/1.1 200 OK
x-page: 1
x-per-page: 100
x-total-count: 6
x-total-pages: 1

[
  {
    "id": 1,
    "title": "A Wizard of Earthsea",
    "description": "A young mage learns his true name, and what it costs.",
    "publish_date": "1968-11-01",
    "rating": 4.67,
    "ratings_count": 3,
    "author_id": 1,
    "created_at": "2026-11-07T23:15:26.476Z",
    "updated_at": "2026-11-07T23:15:26.476Z"
  },
  {
    "id": 2,
    "title": "The Left Hand of Darkness",
    "description": "An envoy on a world without fixed gender.",
    "publish_date": "1969-03-01",
    "rating": 4.0,
    "ratings_count": 2,
    "author_id": 1,
    "created_at": "2026-11-07T23:15:26.491Z",
    "updated_at": "2026-11-07T23:15:26.491Z"
  },
  {
    "id": 3,
    "title": "Guards! Guards!",
    "description": "The Night Watch acquires a dragon problem.",
    "publish_date": "1989-11-10",
    "rating": 4.33,
    "ratings_count": 3,
    "author_id": 2,
    "created_at": "2026-11-07T23:15:26.495Z",
    "updated_at": "2026-11-07T23:15:26.495Z"
  },
  {
    "id": 4,
    "title": "Small Gods",
    "description": "A great god finds himself reduced to a tortoise.",
    "publish_date": "1992-05-01",
    "rating": 3.0,
    "ratings_count": 2,
    "author_id": 2,
    "created_at": "2026-11-07T23:15:26.498Z",
    "updated_at": "2026-11-07T23:15:26.498Z"
  },
  {
    "id": 5,
    "title": "Kindred",
    "description": "A woman is pulled between 1976 California and an antebellum plantation.",
    "publish_date": "1979-06-01",
    "rating": 5.0,
    "ratings_count": 2,
    "author_id": 3,
    "created_at": "2026-11-07T23:15:26.506Z",
    "updated_at": "2026-11-07T23:15:26.506Z"
  },
  {
    "id": 6,
    "title": "Parable of the Sower",
    "description": "A hyperempathic teenager walks north through a collapsing California.",
    "publish_date": "1993-10-01",
    "rating": 3.5,
    "ratings_count": 2,
    "author_id": 3,
    "created_at": "2026-11-07T23:15:26.514Z",
    "updated_at": "2026-11-07T23:15:26.514Z"
  }
]
```

### An absurd page number is an empty page, not a 500

```console
$ curl -i 'http://localhost:8150/api/books?page=99999999999999999999'
HTTP/1.1 200 OK
x-page: 1000000
x-per-page: 25
x-total-count: 6
x-total-pages: 1

[]
```

### An unknown (or injected) sort column falls back to the default ordering

```console
$ curl -i 'http://localhost:8150/api/books/1/reviews?sort_by=id;DROP+TABLE+reviews&per_page=3'
HTTP/1.1 200 OK
x-page: 1
x-per-page: 3
x-total-count: 3
x-total-pages: 1

{
  "reviews": [
    {
      "id": 1,
      "rating": 5,
      "description": "Spare, patient and completely assured.",
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 1,
      "user": {
        "id": 1,
        "first_name": "Ada",
        "last_name": "Lovelace"
      },
      "created_at": "2026-11-07T23:15:26.599Z",
      "updated_at": "2026-11-07T23:15:26.599Z"
    },
    {
      "id": 2,
      "rating": 4,
      "description": null,
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 2,
      "user": {
        "id": 2,
        "first_name": "Grace",
        "last_name": "Hopper"
      },
      "created_at": "2026-11-07T23:15:26.624Z",
      "updated_at": "2026-11-07T23:15:26.624Z"
    },
    {
      "id": 3,
      "rating": 5,
      "description": "The shadow chase still lands.",
      "reviewable_type": "Book",
      "reviewable_id": 1,
      "user_id": 3,
      "user": {
        "id": 3,
        "first_name": "Alan",
        "last_name": "Turing"
      },
      "created_at": "2026-11-07T23:15:26.628Z",
      "updated_at": "2026-11-07T23:15:26.628Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 3,
    "total": 3,
    "total_pages": 1
  }
}
```

## The test suite

```console
$ docker compose --profile test run --rm --build test
Randomized with seed 54229

..................................................................................................................................................................

Finished in 2.09 seconds (files took 0.52899 seconds to load)
162 examples, 0 failures

Randomized with seed 54229
```

## The linter

```console
$ docker compose run --rm --no-deps api bundle exec rubocop
Inspecting 67 files
...................................................................
67 files inspected, no offenses detected
```
