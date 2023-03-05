import os

from flask import Flask
from google.cloud import firestore

app = Flask(__name__)


@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    db = firestore.Client(project='derp-rpoject')

    # Note: Use of CollectionRef stream() is prefered to get()
    cards = db.collection(u'cards').stream()

    for card in cards:
        print(f'{card.id} => {card.to_dict()}')
    return "Hello {}!".format(name)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
