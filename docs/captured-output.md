# Captured output

Every block on this page is real output from the stack that
`docker compose up --build` starts, captured against the seed data in
`db/seeds.rb`. This API has no user interface, so there are no screenshots:
these transcripts are the equivalent.

Responses are piped through `jq` for readability; only the interesting
response headers are shown.

## Booting the stack

```console
$ docker compose up --build
 Container book-reviews-db-1 Created 
 Container book-reviews-api-1 Created 
 Container book-reviews-db-1 Started 
 Container book-reviews-db-1 Healthy 
 Container book-reviews-api-1 Started 
api-1  | ==> waiting for the database
api-1  | ==> preparing the database
api-1  | (schema load and migration output elided)
api-1  | Seeded 3 authors, 6 books, 5 users and 16 reviews.
api-1  | Puma starting in single mode...
api-1  | * Puma version: 5.3.2 (ruby 2.7.2-p137) ("Sweetnighter")
api-1  | *  Min threads: 5
api-1  | *  Max threads: 5
api-1  | *  Environment: production
api-1  | *          PID: 1
api-1  | * Listening on http://0.0.0.0:3000
api-1  | Use Ctrl-C to stop
```

The entrypoint waits for Postgres, runs `db:prepare` and `db:seed`, and only
then starts Puma, so the first request already has data behind it. The seeds
are idempotent, so this is safe on every boot.

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
X-Page: 1
X-Per-Page: 3
X-Total-Count: 6
X-Total-Pages: 2

[
  {
    "id": 1,
    "title": "A Wizard of Earthsea",
    "description": "A young mage learns his true name, and what it costs.",
    "publish_date": "1968-11-01",
    "rating": 4.67,
    "ratings_count": 3,
    "author_id": 1,
    "created_at": "2026-09-23T12:03:02.629Z",
    "updated_at": "2026-09-23T12:03:02.629Z"
  },
  {
    "id": 2,
    "title": "The Left Hand of Darkness",
    "description": "An envoy on a world without fixed gender.",
    "publish_date": "1969-03-01",
    "rating": 4.0,
    "ratings_count": 2,
    "author_id": 1,
    "created_at": "2026-09-23T12:03:02.632Z",
    "updated_at": "2026-09-23T12:03:02.632Z"
  },
  {
    "id": 3,
    "title": "Guards! Guards!",
    "description": "The Night Watch acquires a dragon problem.",
    "publish_date": "1989-11-10",
    "rating": 4.33,
    "ratings_count": 3,
    "author_id": 2,
    "created_at": "2026-09-23T12:03:02.634Z",
    "updated_at": "2026-09-23T12:03:02.634Z"
  }
]
```

### One book

```console
$ curl http://localhost:8150/api/books/1
HTTP/1.1 200 OK

{
  "id": 1,
  "title": "A Wizard of Earthsea",
  "description": "A young mage learns his true name, and what it costs.",
  "publish_date": "1968-11-01",
  "rating": 4.67,
  "ratings_count": 3,
  "author_id": 1,
  "created_at": "2026-09-23T12:03:02.629Z",
  "updated_at": "2026-09-23T12:03:02.629Z"
}
```

### A book's reviews, sorted by rating, highest first

```console
$ curl -i 'http://localhost:8150/api/books/1/reviews?sort_by=rating&order=desc'
HTTP/1.1 200 OK
X-Page: 1
X-Per-Page: 25
X-Total-Count: 3
X-Total-Pages: 1

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
      "created_at": "2026-09-23T12:03:02.666Z",
      "updated_at": "2026-09-23T12:03:02.666Z"
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
      "created_at": "2026-09-23T12:03:02.673Z",
      "updated_at": "2026-09-23T12:03:02.673Z"
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
      "created_at": "2026-09-23T12:03:02.671Z",
      "updated_at": "2026-09-23T12:03:02.671Z"
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
X-Page: 1
X-Per-Page: 25
X-Total-Count: 1
X-Total-Pages: 1

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
      "created_at": "2026-09-23T12:03:02.687Z",
      "updated_at": "2026-09-23T12:03:02.687Z"
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
X-Page: 2
X-Per-Page: 2
X-Total-Count: 3
X-Total-Pages: 2

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
      "created_at": "2026-09-23T12:03:02.673Z",
      "updated_at": "2026-09-23T12:03:02.673Z"
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
$ curl -i 'http://localhost:8150/api/authors/1/reviews'
HTTP/1.1 200 OK
X-Page: 1
X-Per-Page: 25
X-Total-Count: 1
X-Total-Pages: 1

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
      "created_at": "2026-09-23T12:03:02.702Z",
      "updated_at": "2026-09-23T12:03:02.702Z"
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
HTTP/1.1 200 OK

{
  "id": 4,
  "title": "Small Gods",
  "description": "A great god finds himself reduced to a tortoise.",
  "publish_date": "1992-05-01",
  "rating": 4.0,
  "ratings_count": 1,
  "author_id": 2,
  "created_at": "2026-09-23T12:03:02.635Z",
  "updated_at": "2026-09-23T12:03:02.635Z"
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

### The same book afterwards — the average was recomputed on the write

```console
$ curl http://localhost:8150/api/books/4
HTTP/1.1 200 OK

{
  "id": 4,
  "title": "Small Gods",
  "description": "A great god finds himself reduced to a tortoise.",
  "publish_date": "1992-05-01",
  "rating": 3.0,
  "ratings_count": 2,
  "author_id": 2,
  "created_at": "2026-09-23T12:03:02.635Z",
  "updated_at": "2026-09-23T12:03:02.635Z"
}
```

### A second review from the same user is rejected

```console
$ curl -i -X POST http://localhost:8150/api/books/4/reviews -H 'Content-Type: application/json' -d '{"user_id":2,"rating":5}'
HTTP/1.1 422 Unprocessable Entity

{
  "errors": [
    "Reviewable can't post multiple reviews"
  ]
}
```

### A rating outside 1-5 is rejected

```console
$ curl -i -X POST http://localhost:8150/api/books/5/reviews -H 'Content-Type: application/json' -d '{"user_id":1,"rating":9}'
HTTP/1.1 422 Unprocessable Entity

{
  "errors": [
    "Rating rating should be in range of 1..5"
  ]
}
```

### The profanity filter

```console
$ curl -i -X POST http://localhost:8150/api/books/5/reviews -H 'Content-Type: application/json' -d '{"user_id":1,"rating":3,"description":"What a load of gorram nonsense."}'
HTTP/1.1 422 Unprocessable Entity

{
  "errors": [
    "Description cannot contain fictional profanity"
  ]
}
```

### A client-supplied `rating` on a book is ignored

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
  "created_at": "2026-09-23T12:03:02.629Z",
  "updated_at": "2026-09-23T12:03:02.629Z"
}
```

### An unknown book is a 404, not an empty list

```console
$ curl -i 'http://localhost:8150/api/books/999999/reviews'
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
X-Page: 1
X-Per-Page: 100
X-Total-Count: 6
X-Total-Pages: 1

[
  {
    "id": 1,
    "title": "A Wizard of Earthsea",
    "description": "A young mage learns his true name, and what it costs.",
    "publish_date": "1968-11-01",
    "rating": 4.67,
    "ratings_count": 3,
    "author_id": 1,
    "created_at": "2026-09-23T12:03:02.629Z",
    "updated_at": "2026-09-23T12:03:02.629Z"
  },
  {
    "id": 2,
    "title": "The Left Hand of Darkness",
    "description": "An envoy on a world without fixed gender.",
    "publish_date": "1969-03-01",
    "rating": 4.0,
    "ratings_count": 2,
    "author_id": 1,
    "created_at": "2026-09-23T12:03:02.632Z",
    "updated_at": "2026-09-23T12:03:02.632Z"
  },
  {
    "id": 3,
    "title": "Guards! Guards!",
    "description": "The Night Watch acquires a dragon problem.",
    "publish_date": "1989-11-10",
    "rating": 4.33,
    "ratings_count": 3,
    "author_id": 2,
    "created_at": "2026-09-23T12:03:02.634Z",
    "updated_at": "2026-09-23T12:03:02.634Z"
  },
  {
    "id": 4,
    "title": "Small Gods",
    "description": "A great god finds himself reduced to a tortoise.",
    "publish_date": "1992-05-01",
    "rating": 3.0,
    "ratings_count": 2,
    "author_id": 2,
    "created_at": "2026-09-23T12:03:02.635Z",
    "updated_at": "2026-09-23T12:03:02.635Z"
  },
  {
    "id": 5,
    "title": "Kindred",
    "description": "A woman is pulled between 1976 California and an antebellum plantation.",
    "publish_date": "1979-06-01",
    "rating": 5.0,
    "ratings_count": 2,
    "author_id": 3,
    "created_at": "2026-09-23T12:03:02.637Z",
    "updated_at": "2026-09-23T12:03:02.637Z"
  },
  {
    "id": 6,
    "title": "Parable of the Sower",
    "description": "A hyperempathic teenager walks north through a collapsing California.",
    "publish_date": "1993-10-01",
    "rating": 3.5,
    "ratings_count": 2,
    "author_id": 3,
    "created_at": "2026-09-23T12:03:02.639Z",
    "updated_at": "2026-09-23T12:03:02.639Z"
  }
]
```

### An unknown (or injected) sort column falls back to the default ordering

```console
$ curl -i 'http://localhost:8150/api/books/1/reviews?sort_by=id;DROP+TABLE+reviews'
HTTP/1.1 200 OK
X-Page: 1
X-Per-Page: 25
X-Total-Count: 3
X-Total-Pages: 1

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
      "created_at": "2026-09-23T12:03:02.666Z",
      "updated_at": "2026-09-23T12:03:02.666Z"
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
      "created_at": "2026-09-23T12:03:02.671Z",
      "updated_at": "2026-09-23T12:03:02.671Z"
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
      "created_at": "2026-09-23T12:03:02.673Z",
      "updated_at": "2026-09-23T12:03:02.673Z"
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

## The test suite

```console
$ docker compose --profile test run --rm test
......................................................................................................................................................

Finished in 2.57 seconds (files took 0.70938 seconds to load)
150 examples, 0 failures

```

## The linter

```console
$ docker compose run --rm --no-deps api bundle exec rubocop
Inspecting 66 files
..................................................................

66 files inspected, no offenses detected
```
