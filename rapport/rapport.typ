#import "template.typ": *
#show link: it => {
  set text(blue)
  if type(it.dest) != str {
    it
  } else {
    underline(it)
  }
}

#show: project.with(
  subject: "Apprentissage Profond",
  title: "Génération de proverbes",
  authors: (
    "THEVENET Louis",
    "LEBOBE Timothé",
    "TENE Zacharie",
    "SABLAYROLLES Guillaume",
  ),
  date: "31 Mars 2025",
  subtitle: "Groupe L34",
  toc: true,
)


= Génération de proverbes en anglais

Nous avons choisi de créer un modèle de génération de proverbes. La base de donnée est trouvable dans le dossier `raw_data/` à la racine de ce #link("https://github.com/louis-thevenet/n7-deep-learning")[dépôt GitHub]

Voici un exemple de proverbes de notre base d'entraînement :

- He that brings good news, knocks hard.
- Anger and haste hinder good counsel.
- Big thunder, little rain.
- Romeo must die in order to save the love.
- The point is plain as a pike staff.
= Consitution de la base de données
== Acquisition des données

Puisqu'il est plus simple de trouver des données en langue anglaise, nous avons choisi de nous limiter à cette langue et avons utilisé des scripts Python de scrapping pour récolter des données sur différents sites internet.

Nous avons $3200$ proverbes originaux anglais et $35000$ proverbes en incluant des proverbes traduits d'autres langues et prévoyons de tester le modèle sur ces deux bases.

== Partionnement des données

Nous avons choisi de partionner les données de la manière suivante qui est un standart dans l'apprentissage profond :
- 80% des données pour l'apprentissage
- 10% des données pour le test
- 10% des données pour la validation

Nous pourrons augmenter la part d'apprentissage si le manque de donnée a un impact trop important.


== Script de chargement des données

Nous avons réalisé un script de téléchargement et traitement des données. Un exemple d'utilisation est donné dans le fichier `main.ipynb`, il suffit d'appeler le fonction `make_dataset.load_data()` qui renvoie les proverbes classés par sources.

#sourcecode()[```
  proverbs_db.txt: 34142 proverbs
  proverbs_db_only_english.txt: 2208 proverbs
  proverbs_digest.txt: 1000 proverbs
  Total: 37350 proverbs
  Total length: 1853527 characters


  Examples of proverbs:
  Money's for buying and a horse is for riding.
  A set of white teeth does not indicate a pure heart.
  Time discloses the truth.
  The earth has ears, the wind has a voice.
  The fox will catch you with cunning, and the wolf with courage.
  ```]


// Une seconde partie (~5-7 pages) où vous décrirez de façon détaillée votre modèle et son entraînement. Dans cette partie du projet, vous devez avoir à l'esprit pendant votre rédaction que je dois disposer de toutes les informations nécessaires pour reproduire votre travail (liste exhaustive d'hyperparamètres, description détaillée du ou des réseau.x, éventuelles simplifications de la base de données, etc.)

= Création et entraînement du modèle
== Création du modèle
Nous allons faire du fine-tuning à partir du modèle #link("https://huggingface.co/facebook/opt-125m")[`facebook/opt-125`] qui un modèle type GPT-3 basé sur l'architecture Transformers.

Nous testerons également de partir du modèle #link("https://huggingface.co/TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T")[`TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`] qui est plus récent et contient près de dix fois plus de paramètres.


On charge le modèle et son Tokenizer à l'aide des fonctions `AutoModelForCausalLM.from_pretrained()` et `AutoTokenizer.from_pretrained()` de la librarie `transformers`.

On décide des sources de proverbes que l'on va utiliser, puis on les fusionne en une seule liste:
#sourcecode()[```python
  selected_proverbs_groups = [
      "proverbs_db.txt",
      "proverbs_digest.txt"
  ]

  proverbs = []
  for group in selected_proverbs_groups:
      proverbs.extend(all_proverbs[group])  ```]


On utilise ensuite la librarie `datasets` pour préparer ces données à l'entraînement. La tokenisation du dataset consiste à calculer la taille du proverbe le plus long et ajouter du padding aux autres pour uniformiser les tailles.

On utilise ensuite la librarie `peft` afin d'utiliser la technique LoRA (Low-Rank Adaptation). Ainsi, on ajoute un petit nombre de nouveaux paramètres entraînables au modèle afin de l'adapter à la nouvelle tâche.

Paramètres de la configuration LoRA:
#sourcecode()[```python
  LoraConfig(
      r=8,
      lora_alpha=16,
      target_modules=["q_proj", "v_proj"],
      lora_dropout=0.05,
      bias="none",
      task_type="CAUSAL_LM"
  )  ```
]
La méthode `get_peft_model` permet d'obtenir un nouveau modèle à partir de cette configuration de notre modèle initial.

== Entraînement
A l'aide de la librarie `transformers`, on définit les paramètres d'entraînement:

#sourcecode([
  ```python
  TrainingArguments(
      output_dir="./results",
      per_device_train_batch_size=8,
      per_device_eval_batch_size=8,
      num_train_epochs=1,
      logging_dir='./logs',
      logging_steps=10,
      eval_strategy="no",
      save_strategy="epoch",
      report_to="none"
  )

  ```
])

Finalement, on met en commun notre modèle, nos paramètres d'entraînement, notre dataset tokenisé et notre tokeniser via la classe `Trainer` et on peut lancer l'entraînement avec la méthode `train()`.

== Génération

Après entraînement du modèle, on crée un pipeline de génération:
#sourcecode()[```python
  generator = pipeline("text-generation", model=model, tokenizer=tokenizer)
  ```
]
On peut maintenant utiliser le modèle pour terminer un début de proverbes:

#sourcecode()[```python

  prompt = "A"
  results = generator(prompt, max_length=max_length, num_return_sequences=3, do_sample=True, temperature=0.7)

  for i, result in enumerate(results):
      print(result['generated_text'])
  ```
]

Quelques proverbes obtenus:
- A nice dog is a dog.
- A man who keeps his family safe can never be found.
- A child that has no teeth is a coward.


= Analyse des résultats
Les données de sortie étant des proverbes, elles sont difficilement évaluable et comparable et sont sujettes à l'appréciation humaine.

Ainsi nous donnerons quelques résultats non triés à titre d'exemple. Puis dans une seconde partie, nous détaillerons une expérience que nous avons réalisé.

== Entraînement sur les proverbes anglais
On utilise ici les deux sources :
- `proverbs_db_only_english.txt`
- `proverbs_digest.txt`

Pour rappel, cette base de données représente 3208 proverbes originaux en anglais.
=== Modèle de départ `facebook/opt-125m`
Proverbes obtenus à partir de "A" :
#table(
  columns: 2,
  [Proverbe], [Commentaire],
  [A man's only dead when he eats his own. ], [Intéressant],
  [A man can make a woman forget her brother's death. ], [Etrange],
  [A man's heart is full of gold. ], [Intéressant],
  [A good thing is a good thing. ], [Effectivement],
  [A woman’s dream is to be a widow. ], [Etrange],
  [A man dies in the wind, a horse dies in the wind ], [Etrange],
  [A good example of a good example of a good example of a bad example of a bad example of a bad example. ],
  [Incohérent],

  [A few days before you start a new one, you will be remembered for a long time. ],
  [Incohérent],

  [A little of light can be a good thing ], [Intéressant],
)



Proverbes obtenus à partir de "Some" :
#table(
  columns: 2,
  [Proverbe], [Commentaire],
  [Some people have a hard time keeping a family man. ], [Intéressant],
  [Some people are good, some people are good. ], [Incohérent],
  [Some people are lucky to live in a tree. ], [Intéressant],
  [Some of them are to be proud of their first friend. ], [Intéressant],
  [Some times the best is when you are there to be with. ], [Incohérent],
  [Some people have a disease. ], [Etrange],
  [Some people are better than others. ], [Intéressant],
  rows: 1,
  [Some of us are better than others ], [Intéressant],
  [Some people are too silly to forget. ], [Intéressant],
  [Some of those is nothing compared to the sum of them ],
  [Etrange/Intéressant],
)

/ Intéressants: 9
/ Etranges: 4
/ Incohérents: 4


On constate que certains résultats sont incohérents ou étrange. Certains proverbes ressemblent plus à des vérités générales et on trouve quelques proverbes intéressants.

=== Modèle de départ `TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`
Les données sélectionnées ne sont pas assez importante pour obtenir des résultats satisfaisants avec ce modèle.

Exemple de sorties pour "This" :
#table(
  columns: 2,
  [Proverbe], [Commentaire],
  [This is the story of an old woman.], [],
  [This is the way of the world.], [],
  [This is the best.], [],
  [This is the way to get your money's worth.], [],
  [This is the day.], [],
  [This is what you call a new dress.], [],
  [This is a story about a little girl.], [],
  [This is the day the Lord hath spoken. It is the day that the Lord hath spoken.],
  [],

  [This is what happens when we start out on the wrong path.], [],
  [This is my favourite drink.], [],
)
== Entraînement sur les proverbes traduits
=== Modèle de départ `facebook/opt-125m`
On entraîne d'abord sur *20000* proverbes.
=== Modèle de départ `TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`
La RAM disponible ne nous a permis que de sélectionner un maximum de 5000 proverbes.


= Conclusion
