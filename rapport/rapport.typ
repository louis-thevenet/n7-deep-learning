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

Nous également constitué une base de données de proverbes annotés avec leurs thèmes.

Voici quelques exemples :
#figure(caption: "Extrait des proverbes annotés")[
  #sourcecode()[```json
    {
      "topics": ["Advantage"],
      "proverb": "When a rich man caresses a poor man, he's going to take advantage of him."
    }
    {
      "topics": ["Advantage"],
      "proverb": "Every advantage has its disadvantage."
    }
    {
      "topics": ["Advantage", "Vain"],
      "proverb": "He is wise in vain who does not use his wisdom for his own advantage."
    }
    ```
  ]]
// == Partionnement des données

// Nous avons choisi de partionner les données de la manière suivante qui est un standart dans l'apprentissage profond :
// - 80% des données pour l'apprentissage
// - 10% des données pour le test
// - 10% des données pour la validation

// Nous pourrons augmenter la part d'apprentissage si le manque de donnée a un impact trop important.


== Script de chargement des données

Nous avons réalisé un script de téléchargement et traitement des données. Un exemple d'utilisation est donné dans le fichier `main.ipynb`, il suffit d'appeler le fonction `make_dataset.load_data()` qui renvoie les proverbes classés par sources.

#figure(caption: "Proverbes non annotés")[
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
]
De même, la fonction `make_dataset.load_data_with_topics()` renvoie un dataset de données annotées.


// Une seconde partie (~5-7 pages) où vous décrirez de façon détaillée votre modèle et son entraînement. Dans cette partie du projet, vous devez avoir à l'esprit pendant votre rédaction que je dois disposer de toutes les informations nécessaires pour reproduire votre travail (liste exhaustive d'hyperparamètres, description détaillée du ou des réseau.x, éventuelles simplifications de la base de données, etc.)

= Création et entraînement du modèle
== Création du modèle
Nous allons faire du fine-tuning à partir du modèle #link("https://huggingface.co/facebook/opt-125m")[`facebook/opt-125`] qui un modèle type GPT-3 basé sur l'architecture Transformers.

Nous testerons également de partir du modèle #link("https://huggingface.co/TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T")[`TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`] qui est plus récent et contient près de dix fois plus de paramètres.


On charge le modèle et son Tokenizer à l'aide des fonctions `AutoModelForCausalLM.from_pretrained()` et `AutoTokenizer.from_pretrained()` de la librarie `transformers`.

On décide des sources de proverbes que l'on va utiliser, puis on les fusionne en une seule liste.
#figure(caption: "Fusion des listes sélectionnées")[
  #sourcecode()[```python
    selected_proverbs_groups = [
        "proverbs_db.txt",
        "proverbs_digest.txt"
    ]

    proverbs = []
    for group in selected_proverbs_groups:
        proverbs.extend(all_proverbs[group])
    ```]]


On utilise ensuite la librarie `datasets` pour préparer ces données à l'entraînement. La tokenisation du dataset consiste à calculer la taille du proverbe le plus long et ajouter du padding aux autres pour uniformiser les tailles.

On utilise ensuite la librarie `peft` afin d'utiliser la technique LoRA (Low-Rank Adaptation). Ainsi, on ajoute un petit nombre de nouveaux paramètres entraînables au modèle afin de l'adapter à la nouvelle tâche.
#figure(caption: [Configuration LoRA])[#sourcecode()[```python
    LoraConfig(
        r=8,
        lora_alpha=16,
        target_modules=["q_proj", "v_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type="CAUSAL_LM"
    )  ```
  ]]
La méthode `get_peft_model` permet d'obtenir un nouveau modèle à partir de cette configuration de notre modèle initial.

== Entraînement
A l'aide de la librarie `transformers`, on définit les paramètres d'entraînement:

#figure(caption: [Paramètres d'entraînement du modèle])[
  #sourcecode()[
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
  ]]

Finalement, on met en commun notre modèle, nos paramètres d'entraînement, notre dataset tokenisé et notre tokeniser via la classe `Trainer` et on peut lancer l'entraînement avec la méthode `train()`.

== Génération

Après entraînement du modèle, on crée un pipeline de génération.
#figure(caption: "Pipeline de génération")[
  #sourcecode()[```python
    generator = pipeline("text-generation", model=model, tokenizer=tokenizer)
    ```
  ]]

On peut maintenant utiliser le modèle pour terminer un début de proverbes:

#figure(caption: "Génération de proverbes")[
  #sourcecode()[```python
    prompt = "A"
    results = generator(prompt, max_length=max_length, num_return_sequences=3, do_sample=True, temperature=0.7)

    for i, result in enumerate(results):
        print(result['generated_text'])
    ```
  ]]

Quelques proverbes obtenus:
- A nice dog is a dog.
- A man who keeps his family safe can never be found.
- A child that has no teeth is a coward.


= Analyse des résultats
Les données de sortie étant des proverbes, elles sont difficilement évaluables et comparables, et sont sujettes à l'appréciation humaine.

Ainsi nous donnerons quelques résultats non filtrés à titre d'exemple, issus du fine tuning de différents modèles que nous commenterons. Puis dans une seconde partie, nous détaillerons une expérience que nous avons réalisé.
== Génération de proverbes sans thème
=== Entraînement sur les proverbes anglais
On utilise ici les deux sources :
- `proverbs_db_only_english.txt`
- `proverbs_digest.txt`

Pour rappel, cette base de données représente 3208 proverbes originaux en anglais.
==== Modèle de départ `facebook/opt-125m`
#figure(caption: [En partant de "A"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [A man's only dead when he eats his own. ], [Intéressant],
    [A man can make a woman forget her brother's death. ], [Pas un proverbe],
    [A man's heart is full of gold. ], [Pas un proverbe],
    [A good thing is a good thing. ], [Pas un proverbe],
    [A woman’s dream is to be a widow. ], [Etrange],
    [A man dies in the wind, a horse dies in the wind ], [Pas un proverbe],
    [A good example of a good example of a good example of a bad example of a bad example of a bad example. ],
    [Incohérent],

    [A few days before you start a new one, you will be remembered for a long time. ],
    [Incohérent],

    [A little of light can be a good thing ], [Pas un proverbe],
  )
]


#figure(caption: [En partant de "Some"])[
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
    [Some of us are better than others ], [Intéressant],
    [Some people are too silly to forget. ], [Intéressant],
    [Some of those is nothing compared to the sum of them ], [Intéressant],
  )
]

/ Intéressants: 9
/ Etranges: 2
/ Pas un proverbe: 5
/ Incohérents: 4


On constate que certains résultats sont incohérents ou étranges. Certains proverbes ressemblent plus à des vérités générales et on trouve quelques proverbes intéressants.

==== Modèle de départ `TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`
Les données sélectionnées ne sont pas assez importantes pour obtenir des résultats satisfaisants avec ce modèle.

#figure(caption: [En partant de "This"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [This is the story of an old woman.], [Pas un proverbe],
    [This is the way of the world.], [Pas un proverbe],
    [This is the best.], [Pas un proverbe],
    [This is the way to get your money's worth.], [Pas un proverbe],
    [This is the day.], [Pas un proverbe],
    [This is what you call a new dress.], [Pas un proverbe],
    [This is a story about a little girl.], [Pas un proverbe],
    [This is the day the Lord hath spoken. It is the day that the Lord hath spoken.],
    [Pas un proverbe],

    [This is what happens when we start out on the wrong path.],
    [Pas un proverbe],

    [This is my favourite drink.], [Pas un proverbe],
  )

]
/ Intéressants: 0
/ Etrange: 0
/ Pas un proverbe: 10
/ Incohérents: 0


Le modèle de base étant plus important et donc déjà plus entraîné, il ne crée pas de résultat incohérent comme le précédent, mais le dataset utilisé est trop petit pour créer des proverbes intéressants. Peu de proverbes commencent par "Some" dans le dataset. ($4 / 3208 approx #calc.round(100 * 4 / 3208, digits: 2) %$)

=== Entraînement sur les proverbes traduits
==== Modèle de départ `facebook/opt-125m`
On entraîne d'abord sur *20000* proverbes ($#calc.round(100 * 20000 / 35000, digits: 2) %$).
#figure(caption: [En partant de "Some"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [Some men are good at it, some are bad at it, and some are good at it.],
    [Incohérent],

    [Some day people will get one.], [Pas un proverbe],
    [Some days a man wears a leather jacket and a woman wears a leather garment.],
    [Pas un proverbe],

    [Somehow the worst person in the world can make the best at things.],
    [Étrange],

    [Somehow, I am not a thief.], [Pas un proverbe],
    [Some people are more beautiful than others.], [Pas un proverbe],
    [Some day, the sun will rise on a mountain.], [Incohérent],
    [Someones got a good idea and they're good at it.], [Pas un proverbe],
    [Some men have a heart to die for.], [Intéressant],
    [Somehow it looks like a human's ear.], [Incohérent],
  )
]
#figure(caption: [En partant de "A"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [A dog is a beast of a mind.], [Incohérent],
    [A man who makes his wife cry is a thief.], [Étrange],
    [A man's heart is not a dog's tongue.], [Incohérent],
    [A girl may be a good girl, but she has a better chance of getting married.],
    [Étrange],

    [A man who has never seen a woman is a man.], [Incohérent],
    [A house that is just a house is not a house that is a house.],
    [Incohérent],

    [A man who will not sleep for an hour, will not sleep for an hour.],
    [Incohérent],

    [A man cannot take a wife.], [Pas un proverbe],
    [A man who eats meat will not be a judge.], [Étrange],
    [A bit of good luck in life is better than nothing.], [Intéressant],
  )
]

#line(start: (0cm, 0cm), end: (15cm, 0cm), stroke: red)
Pas ouf ces résultats, faudrait réentrainer sur moins de données et savoir l'expliquer
#line(start: (0cm, 0cm), end: (15cm, 0cm), stroke: red)

==== Modèle de départ `TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T`
La RAM disponible ne nous a permis que de sélectionner un maximum de 5000 proverbes.

Cependant, on obtient quand même des résultats plus intéressants qu'avec $3208$ proverbes

#figure(caption: [En partant de "Some"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [Some men are born to lead, and some to follow.], [Intéressant],
    [Some men are so proud of their looks that they never look at the rest of their faces.],
    [Étrange],

    [Someone will not be able to find a wife whom his father chooses.],
    [Pas un proverbe],

    [Some things are good for the body, but not for the stomach.],
    [Intéressant],

    [Some are born with the gift of knowledge, and some with the gift of ignorance.],
    [Intéressant],

    [Some folks make their own pies, and some do not.], [Pas un proverbe],
    [Some people call the wind the sun's enemy.], [Incohérent],
    [Some are wiser than they know. Humor as a way of life is also a part of the world I have to live in.],
    [Incohérent],

    [Some are born great, but some become great by their wit.], [Intéressant],
    [Someone is not what you think about him; you think about him.],
    [Incohérent],
  )
]
#figure(caption: [En partant de "A"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [A man's name is his life.], [Intéressant],
    [A man who has never taken a step should never be trusted.], [Intéressant],
    [A great king cannot be a great man.], [Intéressant],
    [A woman is hard to handle, but easy to cheat.], [Étrange],
    [A dog's nose is better than a man's eyes.], [Intéressant],
    [A woman who has a good head cannot be a fool.], [Intéressant],
    [A bird from a city is a nesting place for many.], [Incohérent],
    [A little knowledge is better than a great ignorance.], [Intéressant],
    [A man who speaks of a hundred will be thought a hundred.], [Incohérent],
    [A man should not be too ambitious.], [Intéressant],
  )
]

/ Intéressants: 11
/ Etranges: 2
/ Incohérents: 5
/ Pas un proverbe: 2

Comme précédemment, ce modèle produit peu de résultat incohérents. On constate qu'on obtient des résultats plus intéressant avec ce dataset plus important, plus adapté à la taille du modèle de base.


=== Expérience avec des humains
A titre d'expérience, nous avons rassemblé $24$ proverbes originaux et générés par nos modèles. (`facebook/opt-125m` sur $approx 15000$ proverbes) Nous avons demandé à $18$ personnes (des professeurs de SHS notamment) de classer chaque proverbe à l'aveugle.
#let total = 18
#let proverb_count = 24
#let result = (
  (
    proverb: "The horse that is not ridden is worse than the horse that is not ridden.",
    generated: [Oui],
    result: 18,
    success_rate: $#calc.round(100 * 18 / total, digits: 2)%$,
  ),
  (
    proverb: "Set a fire and burn it.",
    generated: [Oui],
    result: 11,
    success_rate: $#calc.round(100 * 11 / total, digits: 2)%$,
  ),
  (
    proverb: "Think and thank god.",
    generated: [Non],
    result: 8,
    success_rate: $#calc.round(100 * 8 / total, digits: 2)%$,
  ),
  (
    proverb: "The best way to see divine light is to put out your own candle.",
    generated: [Non],
    result: 12,
    success_rate: $#calc.round(100 * 12 / total, digits: 2)%$,
  ),
  (
    proverb: "The riches of the mind may make a man rich and happy.",
    generated: [Non],
    result: 9,
    success_rate: $#calc.round(100 * 9 / total, digits: 2)%$,
  ),
  (
    proverb: "Who pays in advance eats stinking fish.",
    generated: [Non],
    result: 6,
    success_rate: $#calc.round(100 * 6 / total, digits: 2)%$,
  ),
  (
    proverb: "The nail that sticks out gets pounded.",
    generated: [Non],
    result: 12,
    success_rate: $#calc.round(100 * 12 / total, digits: 2)%$,
  ),
  (
    proverb: "Work paid for in advance has feet of lead.",
    generated: [Non],
    result: 4,
    success_rate: $#calc.round(100 * 4 / total, digits: 2)%$,
  ),
  (
    proverb: "A young child is not born in spite of his own mother.",
    generated: [Oui],
    result: 11,
    success_rate: $#calc.round(100 * 11 / total, digits: 2)%$,
  ),
  (
    proverb: "Set your own goals. An arrow, a sword, and a bottle of wine are enough to keep you from leaving your wife.",
    generated: [Oui],
    result: 13,
    success_rate: $#calc.round(100 * 13 / total, digits: 2)%$,
  ),
  (
    proverb: "All men can’t be first.",
    generated: [Non],
    result: 14,
    success_rate: $#calc.round(100 * 14 / total, digits: 2)%$,
  ),
  (
    proverb: "Don't celebrate until you are across the brook.",
    generated: [Non],
    result: 10,
    success_rate: $#calc.round(100 * 10 / total, digits: 2)%$,
  ),
  (
    proverb: "Such carpenters, such chips.",
    generated: [Non],
    result: 2,
    success_rate: $#calc.round(100 * 2 / total, digits: 2)%$,
  ),
  (
    proverb: "A person's only hope is to give him a good laugh.",
    generated: [Oui],
    result: 15,
    success_rate: $#calc.round(100 * 15 / total, digits: 2)%$,
  ),
  (
    proverb: "To pay one back in one’s own coin.",
    generated: [Non],
    result: 6,
    success_rate: $#calc.round(100 * 6 / total, digits: 2)%$,
  ),
  (
    proverb: "An English friend is a friend.",
    generated: [Oui],
    result: 15,
    success_rate: $#calc.round(100 * 15 / total, digits: 2)%$,
  ),
  (
    proverb: "Romeo must die in order to save the love.",
    generated: [Non],
    result: 3,
    success_rate: $#calc.round(100 * 3 / total, digits: 2)%$,
  ),
  (
    proverb: "The only thing that can be done is to make them believe that they are not going to die.",
    generated: [Oui],
    result: 9,
    success_rate: $#calc.round(100 * 9 / total, digits: 2)%$,
  ),
  (
    proverb: "To be or not to be, you have to be.",
    generated: [Oui],
    result: 14,
    success_rate: $#calc.round(100 * 14 / total, digits: 2)%$,
  ),
  (
    proverb: "Children are poor men’s riches.",
    generated: [Non],
    result: 3,
    success_rate: $#calc.round(100 * 3 / total, digits: 2)%$,
  ),
  (
    proverb: "He, that would eat the fruit, must climb the tree.",
    generated: [Non],
    result: 16,
    success_rate: $#calc.round(100 * 16 / total, digits: 2)%$,
  ),
  (
    proverb: "Do not drink in advance on the hide of a bear.",
    generated: [Non],
    result: 3,
    success_rate: $#calc.round(100 * 3 / total, digits: 2)%$,
  ),
  (
    proverb: "A man's clothing can only last one lifetime.",
    generated: [Oui],
    result: 9,
    success_rate: $#calc.round(100 * 9 / total, digits: 2)%$,
  ),
  (
    proverb: "The musician who is paid in advance does not play so well.",
    generated: [Non],
    result: 9,
    success_rate: $#calc.round(100 * 9 / total, digits: 2)%$,
  ),
)

#let table-json(data) = {
  data = data.map(v => {
    (
      Proverbe: v.proverb,
      Generé: v.generated,
      TauxSuccès: v.success_rate,
    )
  })
  let keys = data.at(0).keys()

  table(
    columns: keys.len(),
    ..keys,
    ..data.map(row => keys.map(key => row.at(key, default: [n/a]))).flatten()
  )
}
#figure(caption: "Résultats de l'éxpérience par proverbe")[#table-json(result)]


#let non_gen_correct = (
  result.filter(e => e.generated == [Non]).map(e => e.result).sum()
)
#let gen_correct = (
  result.filter(e => e.generated == [Oui]).map(e => e.result).sum()
)
#let non_gen_incorrect = (
  result.filter(e => e.generated == [Non]).map(e => total - e.result).sum()
)
#let gen_incorrect = (
  result.filter(e => e.generated == [Oui]).map(e => total - e.result).sum()
)
#let prov_times_answer = proverb_count * total
#figure(caption: "Résultats de l'expérience")[

  #table(
    columns: 4,
    [], [Générés], [Non générés], [Total ($%$)],
    [Bien détéctés],
    [#gen_correct],
    [#non_gen_correct],
    [#{
        calc.round(
          100 * (gen_correct + non_gen_correct) / prov_times_answer,
          digits: 3,
        )
      }
    ],

    [Mal détéctés],
    [#non_gen_incorrect],
    [#gen_incorrect],
    [#{
        calc.round(
          100 * (non_gen_incorrect + gen_incorrect) / prov_times_answer,
          digits: 3,
        )
      }
    ],

    [Total ($%$)],
    [#{
        calc.round(
          100 * (gen_correct + gen_incorrect) / prov_times_answer,
          digits: 3,
        )
      }],
    [#{
        calc.round(
          100 * (non_gen_correct + non_gen_incorrect) / prov_times_answer,
          digits: 3,
        )
      }
    ],
    [#{
        (
          calc.round(
            100
              * (
                gen_correct
                  + gen_incorrect
                  + non_gen_correct
                  + non_gen_incorrect
              )
              / prov_times_answer,
            digits: 3,
          )
        )
      }
    ],
  )
]

== Génération avec thème

On a ici entraîné le modèle `facebook/opt-125m` sur $20000$ proverbes ($#calc.round(100 * 20000 / 35000, digits: 2) %$) annotés avec leurs thèmes ($1$ heure d'entraînement).
#figure(caption: [Avec le thème "Love"])[
  #table(
    columns: 2,
    [Proverbe], [Commentaire],
    [The love of one is not always the love of all. ], [Intéressant],
    [If you love a woman, she will be love. ], [Etrange],
    [If you love a man, you will be love.], [Etrange],
    [Love is love, and with love we can go out of love and into another. ],
    [Etrange],

    [Love is the best proverb. ], [Intéressant],
    [It is a good proverb, but a proverb is better. ], [Incohérent],
    [Love has no love. ], [Etrange],
    [It is love that first love is in the end. ], [Intéressant],
    [Never in love. It's not love. ], [Intéressant],
    [Love the love of the love of peace, and the love of the love of the love of the love of the peace... ],
    [Incohérent],

    [The woman heches the dog, but the man sheches the dog. ], [Etrange],
    [If love can't be found or found without fear, it can't be found without fear. ],
    [Etrange],
  )]

= Conclusion
