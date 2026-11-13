# V2 Stage 4 Question Bank Draft (Task 4.1)

> **Status:** Draft for review only. **Do NOT add to `lib/data/quiz_questions.dart` yet.**  
> **Target:** 60 new questions (15 per subject) expanding the current 40-question bank to 100 questions (25 per subject).  
> **Difficulty Distribution Target per Subject:** ~40% easy (difficulty 1), ~40% medium (difficulty 2), ~20% hard (difficulty 3). (e.g. 6 easy, 6 medium, 3 hard).

---

## 1. Calculus (`calc_11` – `calc_25`)

### calc_11
- **Topic:** Derivatives
- **Difficulty:** 1 (Easy)
- **Question:** What is the derivative of a constant value $c$ with respect to $x$ (for example, $\frac{d}{dx}[5]$)?
- **Options:**
  - [x] A) 0
  - [ ] B) 1
  - [ ] C) $c$
  - [ ] D) Undefined
- **Correct Index:** 0
- **Explanation:** The derivative represents the instantaneous rate of change. A constant value never changes, so its slope and derivative are always 0.

### calc_12
- **Topic:** Derivatives
- **Difficulty:** 1 (Easy)
- **Question:** What is the derivative of $5x^3$?
- **Options:**
  - [x] A) $15x^2$
  - [ ] B) $5x^2$
  - [ ] C) $15x^3$
  - [ ] D) $8x^2$
- **Correct Index:** 0
- **Explanation:** Using the constant multiple and power rules: $\frac{d}{dx}[5x^3] = 5 \cdot 3x^{3-1} = 15x^2$.

### calc_13
- **Topic:** Limits
- **Difficulty:** 1 (Easy)
- **Question:** What is the limit of $f(x) = 2x + 3$ as $x$ approaches 4?
- **Options:**
  - [x] A) 11
  - [ ] B) 8
  - [ ] C) 14
  - [ ] D) 7
- **Correct Index:** 0
- **Explanation:** Polynomial functions are continuous everywhere, so the limit is evaluated by direct substitution: $2(4) + 3 = 11$.

### calc_14
- **Topic:** Integrals
- **Difficulty:** 1 (Easy)
- **Question:** What is the definite integral $\int_0^2 2x \, dx$?
- **Options:**
  - [x] A) 4
  - [ ] B) 2
  - [ ] C) 8
  - [ ] D) 1
- **Correct Index:** 0
- **Explanation:** The antiderivative of $2x$ is $x^2$. Evaluating from 0 to 2 gives $[x^2]_0^2 = 2^2 - 0^2 = 4$.

### calc_15
- **Topic:** Derivatives
- **Difficulty:** 1 (Easy)
- **Question:** What is the derivative of $\cos(x)$ with respect to $x$?
- **Options:**
  - [x] A) $-\sin(x)$
  - [ ] B) $\sin(x)$
  - [ ] C) $-\cos(x)$
  - [ ] D) $\tan(x)$
- **Correct Index:** 0
- **Explanation:** The derivative of cosine is negative sine: $\frac{d}{dx}[\cos(x)] = -\sin(x)$.

### calc_16
- **Topic:** Integrals
- **Difficulty:** 1 (Easy)
- **Question:** What is the indefinite integral $\int x^3 \, dx$?
- **Options:**
  - [x] A) $\frac{x^4}{4} + C$
  - [ ] B) $3x^2 + C$
  - [ ] C) $\frac{x^3}{3} + C$
  - [ ] D) $4x^4 + C$
- **Correct Index:** 0
- **Explanation:** By the reverse power rule: $\int x^n \, dx = \frac{x^{n+1}}{n+1} + C$. For $n=3$, this gives $\frac{x^4}{4} + C$.

### calc_17
- **Topic:** Derivatives
- **Difficulty:** 2 (Medium)
- **Question:** According to the product rule, what is $\frac{d}{dx}[u(x) \cdot v(x)]$?
- **Options:**
  - [x] A) $u'(x)v(x) + u(x)v'(x)$
  - [ ] B) $u'(x)v'(x)$
  - [ ] C) $u'(x)v(x) - u(x)v'(x)$
  - [ ] D) $\frac{u'(x)}{v'(x)}$
- **Correct Index:** 0
- **Explanation:** The product rule states that the derivative of a product is the derivative of the first times the second plus the first times the derivative of the second.

### calc_18
- **Topic:** Derivatives
- **Difficulty:** 2 (Medium)
- **Question:** What is the derivative of $\tan(x)$ with respect to $x$?
- **Options:**
  - [x] A) $\sec^2(x)$
  - [ ] B) $\csc^2(x)$
  - [ ] C) $\sec(x)\tan(x)$
  - [ ] D) $\cot(x)$
- **Correct Index:** 0
- **Explanation:** $\frac{d}{dx}[\tan(x)] = \frac{d}{dx}\left[\frac{\sin(x)}{\cos(x)}\right] = \frac{\cos^2(x) + \sin^2(x)}{\cos^2(x)} = \frac{1}{\cos^2(x)} = \sec^2(x)$.

### calc_19
- **Topic:** Limits
- **Difficulty:** 2 (Medium)
- **Question:** What is $\lim_{x \to 2} \frac{x^2 - 4}{x - 2}$?
- **Options:**
  - [x] A) 4
  - [ ] B) 0
  - [ ] C) 2
  - [ ] D) Undefined
- **Correct Index:** 0
- **Explanation:** Factoring the numerator gives $(x - 2)(x + 2)$. Canceling $(x - 2)$ for $x \neq 2$ leaves $\lim_{x \to 2} (x + 2) = 4$.

### calc_20
- **Topic:** Integrals
- **Difficulty:** 2 (Medium)
- **Question:** What is the indefinite integral $\int e^{3x} \, dx$?
- **Options:**
  - [x] A) $\frac{1}{3}e^{3x} + C$
  - [ ] B) $3e^{3x} + C$
  - [ ] C) $e^{3x} + C$
  - [ ] D) $\frac{1}{3}e^x + C$
- **Correct Index:** 0
- **Explanation:** Using substitution with $u = 3x$ and $du = 3\,dx$, $\int e^{3x} \, dx = \frac{1}{3}\int e^u \, du = \frac{1}{3}e^{3x} + C$.

### calc_21
- **Topic:** Derivatives
- **Difficulty:** 2 (Medium)
- **Question:** What is the slope of the tangent line to $y = x^2 - 3x$ at the point where $x = 4$?
- **Options:**
  - [x] A) 5
  - [ ] B) 4
  - [ ] C) 8
  - [ ] D) 1
- **Correct Index:** 0
- **Explanation:** The slope is given by the derivative $y' = 2x - 3$. At $x = 4$, $y'(4) = 2(4) - 3 = 5$.

### calc_22
- **Topic:** Optimization
- **Difficulty:** 2 (Medium)
- **Question:** At what value of $x$ does the curve $f(x) = x^2 - 6x + 5$ reach its local minimum?
- **Options:**
  - [x] A) $x = 3$
  - [ ] B) $x = 6$
  - [ ] C) $x = 0$
  - [ ] D) $x = -3$
- **Correct Index:** 0
- **Explanation:** Critical points occur where $f'(x) = 0$. $f'(x) = 2x - 6 = 0 \implies x = 3$. Since $f''(3) = 2 > 0$, this is a local minimum.

### calc_23
- **Topic:** Integrals
- **Difficulty:** 3 (Hard)
- **Question:** What technique is typically used to integrate $\int x \cos(x) \, dx$?
- **Options:**
  - [x] A) Integration by parts ($\int u\,dv = uv - \int v\,du$)
  - [ ] B) Partial fraction decomposition
  - [ ] C) Trigonometric substitution with $x = \tan(\theta)$
  - [ ] D) Direct power rule
- **Correct Index:** 0
- **Explanation:** Integration by parts applies to products of algebraic and trigonometric functions. Setting $u = x$ and $dv = \cos(x)\,dx$ yields $x\sin(x) + \cos(x) + C$.

### calc_24
- **Topic:** Limits
- **Difficulty:** 3 (Hard)
- **Question:** When applying L'Hôpital's Rule to an indeterminate limit of form $\frac{0}{0}$ or $\frac{\infty}{\infty}$, what does $\lim_{x \to c} \frac{f(x)}{g(x)}$ equal?
- **Options:**
  - [x] A) $\lim_{x \to c} \frac{f'(x)}{g'(x)}$
  - [ ] B) $\lim_{x \to c} \frac{f'(x)g(x) - f(x)g'(x)}{g(x)^2}$
  - [ ] C) $\frac{\lim f'(x)}{\lim g(x)}$
  - [ ] D) $\lim_{x \to c} (f'(x) - g'(x))$
- **Correct Index:** 0
- **Explanation:** L'Hôpital's Rule states that under suitable differentiability conditions, $\lim \frac{f(x)}{g(x)} = \lim \frac{f'(x)}{g'(x)}$.

### calc_25
- **Topic:** Series
- **Difficulty:** 3 (Hard)
- **Question:** What is the Maclaurin series expansion for $e^x$?
- **Options:**
  - [x] A) $\sum_{n=0}^{\infty} \frac{x^n}{n!} = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \dots$
  - [ ] B) $\sum_{n=1}^{\infty} \frac{(-1)^n x^n}{n}$
  - [ ] C) $\sum_{n=0}^{\infty} x^n = 1 + x + x^2 + x^3 + \dots$
  - [ ] D) $\sum_{n=0}^{\infty} \frac{(-1)^n x^{2n+1}}{(2n+1)!}$
- **Correct Index:** 0
- **Explanation:** Since all derivatives of $e^x$ evaluated at 0 are 1, Taylor's formula yields $\sum_{n=0}^{\infty} \frac{f^{(n)}(0)}{n!}x^n = \sum_{n=0}^{\infty} \frac{x^n}{n!}$.

---

## 2. Biology (`bio_11` – `bio_25`)

### bio_11
- **Topic:** Ecology
- **Difficulty:** 1 (Easy)
- **Question:** What term describes organisms that produce their own food from sunlight or inorganic substances?
- **Options:**
  - [x] A) Autotrophs
  - [ ] B) Heterotrophs
  - [ ] C) Decomposers
  - [ ] D) Herbivores
- **Correct Index:** 0
- **Explanation:** Autotrophs (such as green plants and algae) synthesize organic compounds from simple inorganic raw materials.

### bio_12
- **Topic:** Cell Structure
- **Difficulty:** 1 (Easy)
- **Question:** Which cellular structure is responsible for protein synthesis?
- **Options:**
  - [x] A) Ribosome
  - [ ] B) Lysosome
  - [ ] C) Centrosome
  - [ ] D) Vacuole
- **Correct Index:** 0
- **Explanation:** Ribosomes translate messenger RNA (mRNA) sequences into amino acid chains to form proteins.

### bio_13
- **Topic:** Genetics
- **Difficulty:** 1 (Easy)
- **Question:** In DNA base pairing, which nitrogenous base always pairs with Adenine (A)?
- **Options:**
  - [x] A) Thymine (T)
  - [ ] B) Cytosine (C)
  - [ ] C) Guanine (G)
  - [ ] D) Uracil (U)
- **Correct Index:** 0
- **Explanation:** According to Chargaff's rules of DNA base pairing, Adenine pairs with Thymine (via two hydrogen bonds), and Guanine pairs with Cytosine.

### bio_14
- **Topic:** Physiology
- **Difficulty:** 1 (Easy)
- **Question:** Which human organ produces insulin to regulate blood sugar levels?
- **Options:**
  - [x] A) Pancreas
  - [ ] B) Liver
  - [ ] C) Kidney
  - [ ] D) Gallbladder
- **Correct Index:** 0
- **Explanation:** The beta cells of the islets of Langerhans in the pancreas secrete insulin in response to elevated blood glucose.

### bio_15
- **Topic:** Cell Structure
- **Difficulty:** 1 (Easy)
- **Question:** Which organelle contains digestive enzymes that break down cellular waste and foreign invaders?
- **Options:**
  - [x] A) Lysosome
  - [ ] B) Endoplasmic reticulum
  - [ ] C) Nucleolus
  - [ ] D) Peroxisome
- **Correct Index:** 0
- **Explanation:** Lysosomes act as the digestive/waste-disposal system of the cell using hydrolytic enzymes.

### bio_16
- **Topic:** Photosynthesis
- **Difficulty:** 1 (Easy)
- **Question:** What gas do plants absorb from the atmosphere for use in photosynthesis?
- **Options:**
  - [x] A) Carbon dioxide ($CO_2$)
  - [ ] B) Oxygen ($O_2$)
  - [ ] C) Nitrogen ($N_2$)
  - [ ] D) Methane ($CH_4$)
- **Correct Index:** 0
- **Explanation:** Plants take in carbon dioxide through their stomata to provide the carbon backbone for glucose synthesis in the Calvin cycle.

### bio_17
- **Topic:** Genetics
- **Difficulty:** 2 (Medium)
- **Question:** If two heterozygous pea plants ($Bb$) are crossed, what is the expected phenotypic ratio of dominant to recessive traits?
- **Options:**
  - [x] A) 3:1
  - [ ] B) 1:2:1
  - [ ] C) 1:1
  - [ ] D) 9:3:3:1
- **Correct Index:** 0
- **Explanation:** A monohybrid cross ($Bb \times Bb$) produces genotypes $1\,BB : 2\,Bb : 1\,bb$. Since $BB$ and $Bb$ exhibit the dominant phenotype, the phenotypic ratio is 3 dominant : 1 recessive.

### bio_18
- **Topic:** Cell Respiration
- **Difficulty:** 2 (Medium)
- **Question:** Where does glycolysis take place within a eukaryotic cell?
- **Options:**
  - [x] A) Cytoplasm (Cytosol)
  - [ ] B) Mitochondrial matrix
  - [ ] C) Inner mitochondrial membrane
  - [ ] D) Nucleus
- **Correct Index:** 0
- **Explanation:** Glycolysis occurs in the cytosol/cytoplasm without requiring oxygen, splitting glucose into two pyruvate molecules.

### bio_19
- **Topic:** Physiology
- **Difficulty:** 2 (Medium)
- **Question:** In the human circulatory system, which blood vessels carry oxygenated blood from the lungs back to the left atrium of the heart?
- **Options:**
  - [x] A) Pulmonary veins
  - [ ] B) Pulmonary arteries
  - [ ] C) Superior vena cava
  - [ ] D) Aorta
- **Correct Index:** 0
- **Explanation:** Although most veins carry deoxygenated blood, the pulmonary veins carry freshly oxygenated blood from the pulmonary capillaries to the left atrium.

### bio_20
- **Topic:** Ecology
- **Difficulty:** 2 (Medium)
- **Question:** In an ecological energy pyramid, approximately what percentage of energy is transferred from one trophic level to the next?
- **Options:**
  - [x] A) 10%
  - [ ] B) 50%
  - [ ] C) 1%
  - [ ] D) 25%
- **Correct Index:** 0
- **Explanation:** Lindeman's 10% law states that only about 10% of chemical energy is transferred up each trophic level; the rest is lost primarily as heat and metabolic work.

### bio_21
- **Topic:** Evolution
- **Difficulty:** 2 (Medium)
- **Question:** What evolutionary term describes anatomical structures that share a common ancestral origin but have different functions (e.g. human arm and bat wing)?
- **Options:**
  - [x] A) Homologous structures
  - [ ] B) Analogous structures
  - [ ] C) Vestigial structures
  - [ ] D) Convergent structures
- **Correct Index:** 0
- **Explanation:** Homologous structures reflect divergent evolution from a common ancestor, while analogous structures perform similar functions without shared ancestry.

### bio_22
- **Topic:** Molecular Biology
- **Difficulty:** 2 (Medium)
- **Question:** During transcription in protein synthesis, what replaces Thymine when mRNA is synthesized from a DNA template?
- **Options:**
  - [x] A) Uracil (U)
  - [ ] B) Cytosine (C)
  - [ ] C) Guanine (G)
  - [ ] D) Adenine (A)
- **Correct Index:** 0
- **Explanation:** RNA molecules contain the pyrimidine Uracil (U) instead of Thymine (T) to pair with Adenine.

### bio_23
- **Topic:** Cell Respiration
- **Difficulty:** 3 (Hard)
- **Question:** In aerobic cellular respiration, which stage produces the largest amount of ATP via oxidative phosphorylation?
- **Options:**
  - [x] A) Electron transport chain & chemiosmosis
  - [ ] B) Krebs cycle (Citric acid cycle)
  - [ ] C) Glycolysis
  - [ ] D) Pyruvate oxidation
- **Correct Index:** 0
- **Explanation:** The electron transport chain and ATP synthase generate roughly 26 to 28 ATP per glucose through a proton gradient, far exceeding the 2 ATP from glycolysis and 2 ATP from the Krebs cycle.

### bio_24
- **Topic:** Molecular Biology
- **Difficulty:** 3 (Hard)
- **Question:** What is the primary role of DNA Ligase during DNA replication?
- **Options:**
  - [x] A) Joining Okazaki fragments on the lagging strand
  - [ ] B) Unwinding the double helix at the replication fork
  - [ ] C) Synthesizing short RNA primers
  - [ ] D) Proofreading nucleotide mismatches
- **Correct Index:** 0
- **Explanation:** DNA ligase catalyzes the formation of phosphodiester bonds, sealing nicks and joining discontinuous Okazaki fragments on the lagging strand.

### bio_25
- **Topic:** Genetics
- **Difficulty:** 3 (Hard)
- **Question:** The Hardy-Weinberg equilibrium equation $p^2 + 2pq + q^2 = 1$ models allele and genotype frequencies under which condition?
- **Options:**
  - [x] A) No mutation, random mating, no gene flow, large population, and no natural selection
  - [ ] B) High mutation rate and strong sexual selection
  - [ ] C) Small isolated population with genetic drift
  - [ ] D) Directional natural selection favoring heterozygotes
- **Correct Index:** 0
- **Explanation:** Hardy-Weinberg equilibrium requires five ideal conditions: no natural selection, no mutation, no migration (gene flow), extremely large population size (no genetic drift), and random mating.

---

## 3. History (`hist_11` – `hist_25`)

### hist_11
- **Topic:** Ancient Civilizations
- **Difficulty:** 1 (Easy)
- **Question:** Which ancient river system was fundamental to the development of early Mesopotamian civilization?
- **Options:**
  - [x] A) Tigris and Euphrates
  - [ ] B) Nile
  - [ ] C) Indus and Ganges
  - [ ] D) Yellow River
- **Correct Index:** 0
- **Explanation:** Mesopotamia (meaning "land between rivers") flourished in the fertile valley between the Tigris and Euphrates rivers in modern-day Iraq and Syria.

### hist_12
- **Topic:** World War II
- **Difficulty:** 1 (Easy)
- **Question:** What surprise military strike brought the United States into World War II in December 1941?
- **Options:**
  - [x] A) Attack on Pearl Harbor
  - [ ] B) Battle of Midway
  - [ ] C) Sinking of the Bismarck
  - [ ] D) Invasion of Normandy
- **Correct Index:** 0
- **Explanation:** The Imperial Japanese Navy attacked the US naval base at Pearl Harbor, Hawaii on December 7, 1941, leading the US to declare war the following day.

### hist_13
- **Topic:** Renaissance
- **Difficulty:** 1 (Easy)
- **Question:** Who painted the iconic portrait known as the Mona Lisa?
- **Options:**
  - [x] A) Leonardo da Vinci
  - [ ] B) Michelangelo
  - [ ] C) Raphael
  - [ ] D) Donatello
- **Correct Index:** 0
- **Explanation:** Italian Renaissance polymath Leonardo da Vinci painted the Mona Lisa in the early 16th century.

### hist_14
- **Topic:** American Revolution
- **Difficulty:** 1 (Easy)
- **Question:** Who was unanimously elected as the first President of the United States under the US Constitution?
- **Options:**
  - [x] A) George Washington
  - [ ] B) John Adams
  - [ ] C) Thomas Jefferson
  - [ ] D) Alexander Hamilton
- **Correct Index:** 0
- **Explanation:** George Washington served as the commander-in-chief of the Continental Army and was inaugurated as the first US President in 1789.

### hist_15
- **Topic:** World War I
- **Difficulty:** 1 (Easy)
- **Question:** What international peace organization was established following World War I to prevent future global conflict?
- **Options:**
  - [x] A) League of Nations
  - [ ] B) United Nations
  - [ ] C) North Atlantic Treaty Organization (NATO)
  - [ ] D) Warsaw Pact
- **Correct Index:** 0
- **Explanation:** Championed in Woodrow Wilson's Fourteen Points, the League of Nations was founded in 1920 by the Treaty of Versailles.

### hist_16
- **Topic:** Ancient Civilizations
- **Difficulty:** 1 (Easy)
- **Question:** Which Greek city-state was famous for its democratic governance and philosophical schools?
- **Options:**
  - [x] A) Athens
  - [ ] B) Sparta
  - [ ] C) Corinth
  - [ ] D) Thebes
- **Correct Index:** 0
- **Explanation:** Classical Athens is celebrated as the birthplace of direct democracy and the home of Socrates, Plato, and Aristotle.

### hist_17
- **Topic:** French Revolution
- **Difficulty:** 2 (Medium)
- **Question:** In what year did French revolutionaries storm the Bastille fortress, marking a key milestone of the French Revolution?
- **Options:**
  - [x] A) 1789
  - [ ] B) 1776
  - [ ] C) 1799
  - [ ] D) 1804
- **Correct Index:** 0
- **Explanation:** The Storming of the Bastille occurred on July 14, 1789, symbolizing the popular rebellion against royal despotism in France.

### hist_18
- **Topic:** Cold War
- **Difficulty:** 2 (Medium)
- **Question:** Which 1962 confrontation between the US and the USSR brought the world to the brink of nuclear war?
- **Options:**
  - [x] A) Cuban Missile Crisis
  - [ ] B) Berlin Airlift
  - [ ] C) Suez Crisis
  - [ ] D) Korean Armistice
- **Correct Index:** 0
- **Explanation:** The 13-day Cuban Missile Crisis in October 1962 followed the discovery of Soviet ballistic nuclear missiles deployed in Cuba.

### hist_19
- **Topic:** Medieval History
- **Difficulty:** 2 (Medium)
- **Question:** What devastating pandemic swept through Europe between 1347 and 1351, wiping out an estimated one-third to one-half of the population?
- **Options:**
  - [x] A) The Black Death (Bubonic Plague)
  - [ ] B) The Spanish Flu
  - [ ] C) The Justinian Plague
  - [ ] D) The Antonine Plague
- **Correct Index:** 0
- **Explanation:** The Black Death, caused by the bacterium *Yersinia pestis*, dramatically transformed European demographics, economics, and feudal structures.

### hist_20
- **Topic:** World War II
- **Difficulty:** 2 (Medium)
- **Question:** What was the code name for the Allied amphibious invasion of Normandy on June 6, 1944 (D-Day)?
- **Options:**
  - [x] A) Operation Overlord
  - [ ] B) Operation Barbarossa
  - [ ] C) Operation Market Garden
  - [ ] D) Operation Torch
- **Correct Index:** 0
- **Explanation:** Operation Overlord was the Western Allied offensive that opened a major western front and liberated Western Europe from Nazi occupation.

### hist_21
- **Topic:** Industrial Revolution
- **Difficulty:** 2 (Medium)
- **Question:** In which country did the Industrial Revolution originate in the mid-18th century?
- **Options:**
  - [x] A) Great Britain
  - [ ] B) Germany
  - [ ] C) United States
  - [ ] D) France
- **Correct Index:** 0
- **Explanation:** Abundant coal, iron ore, naval trade power, and innovations in steam and textiles made Great Britain the cradle of the Industrial Revolution.

### hist_22
- **Topic:** Ancient Civilizations
- **Difficulty:** 2 (Medium)
- **Question:** Which Macedonian king conquered the Persian Empire and established an empire stretching from Greece to northwestern India?
- **Options:**
  - [x] A) Alexander the Great
  - [ ] B) Philip II
  - [ ] C) Darius III
  - [ ] D) Cyrus the Great
- **Correct Index:** 0
- **Explanation:** Alexander III of Macedon (Alexander the Great) created one of history's largest empires before dying in Babylon in 323 BCE.

### hist_23
- **Topic:** World War I
- **Difficulty:** 3 (Hard)
- **Question:** What peace treaty concluded World War I with Germany and imposed strict reparations and the "War Guilt" clause?
- **Options:**
  - [x] A) Treaty of Versailles
  - [ ] B) Treaty of Brest-Litovsk
  - [ ] C) Treaty of Saint-Germain
  - [ ] D) Congress of Vienna
- **Correct Index:** 0
- **Explanation:** Signed in June 1919, the Treaty of Versailles forced Germany under Article 231 to accept sole responsibility for starting the war and pay substantial reparations.

### hist_24
- **Topic:** Cold War
- **Difficulty:** 3 (Hard)
- **Question:** Which Soviet leader introduced the dual reform policies of *Glasnost* (openness) and *Perestroika* (restructuring) in the 1980s?
- **Options:**
  - [x] A) Mikhail Gorbachev
  - [ ] B) Nikita Khrushchev
  - [ ] C) Leonid Brezhnev
  - [ ] D) Boris Yeltsin
- **Correct Index:** 0
- **Explanation:** Mikhail Gorbachev implemented Glasnost and Perestroika in an effort to modernize the Soviet economic and political system, unintentionally hastening the USSR's dissolution.

### hist_25
- **Topic:** Medieval History
- **Difficulty:** 3 (Hard)
- **Question:** The fall of which imperial capital to the Ottoman Turks under Sultan Mehmed II in 1453 marked the end of the Byzantine Empire?
- **Options:**
  - [x] A) Constantinople
  - [ ] B) Alexandria
  - [ ] C) Antioch
  - [ ] D) Ravenna
- **Correct Index:** 0
- **Explanation:** The Ottoman conquest of Constantinople in May 1453 ended more than a thousand years of the Eastern Roman (Byzantine) Empire and redirected European trade routes.

---

## 4. Physics (`phys_11` – `phys_25`)

### phys_11
- **Topic:** Mechanics
- **Difficulty:** 1 (Easy)
- **Question:** What is the SI unit of force?
- **Options:**
  - [x] A) Newton ($N$)
  - [ ] B) Joule ($J$)
  - [ ] C) Pascal ($Pa$)
  - [ ] D) Watt ($W$)
- **Correct Index:** 0
- **Explanation:** Force is measured in Newtons ($N$), where $1\,N = 1\,\text{kg}\cdot\text{m/s}^2$, honoring Sir Isaac Newton.

### phys_12
- **Topic:** Energy
- **Difficulty:** 1 (Easy)
- **Question:** What type of energy is stored in an object due to its elevated position in a gravitational field?
- **Options:**
  - [x] A) Gravitational potential energy
  - [ ] B) Kinetic energy
  - [ ] C) Thermal energy
  - [ ] D) Chemical potential energy
- **Correct Index:** 0
- **Explanation:** Gravitational potential energy ($PE = mgh$) is the potential work an object can do by falling from height $h$.

### phys_13
- **Topic:** Electromagnetism
- **Difficulty:** 1 (Easy)
- **Question:** What is the SI unit of electrical current?
- **Options:**
  - [x] A) Ampere ($A$)
  - [ ] B) Volt ($V$)
  - [ ] C) Coulomb ($C$)
  - [ ] D) Ohm ($\Omega$)
- **Correct Index:** 0
- **Explanation:** Electric current is the rate of charge flow ($I = Q/t$) and is measured in Amperes (Coulombs per second).

### phys_14
- **Topic:** Thermodynamics
- **Difficulty:** 1 (Easy)
- **Question:** What temperature is defined as absolute zero (the theoretical absence of all thermal motion) on the Celsius scale?
- **Options:**
  - [x] A) $-273.15^\circ\text{C}$
  - [ ] B) $-100^\circ\text{C}$
  - [ ] C) $0^\circ\text{C}$
  - [ ] D) $-459.67^\circ\text{C}$
- **Correct Index:** 0
- **Explanation:** Absolute zero corresponds to 0 Kelvin or $-273.15^\circ\text{C}$.

### phys_15
- **Topic:** Optics & Waves
- **Difficulty:** 1 (Easy)
- **Question:** What phenomenon describes the bending of a light wave as it passes from one medium into another of differing density?
- **Options:**
  - [x] A) Refraction
  - [ ] B) Reflection
  - [ ] C) Diffraction
  - [ ] D) Polarization
- **Correct Index:** 0
- **Explanation:** Refraction occurs because light changes its phase velocity when transitioning between optical media with different refractive indices.

### phys_16
- **Topic:** Mechanics
- **Difficulty:** 1 (Easy)
- **Question:** What physical quantity is the product of an object's mass and its velocity ($p = mv$)?
- **Options:**
  - [x] A) Linear momentum
  - [ ] B) Angular acceleration
  - [ ] C) Mechanical work
  - [ ] D) Impulse
- **Correct Index:** 0
- **Explanation:** Linear momentum is a vector quantity defined as $p = mv$, conserved in closed systems without external forces.

### phys_17
- **Topic:** Electromagnetism
- **Difficulty:** 2 (Medium)
- **Question:** According to Ohm's Law ($V = IR$), what is the current passing through a $10\,\Omega$ resistor connected across a $50\,\text{V}$ power source?
- **Options:**
  - [x] A) $5\,\text{A}$
  - [ ] B) $0.2\,\text{A}$
  - [ ] C) $500\,\text{A}$
  - [ ] D) $40\,\text{A}$
- **Correct Index:** 0
- **Explanation:** Rearranging Ohm's law gives $I = V / R = 50\,\text{V} / 10\,\Omega = 5\,\text{A}$.

### phys_18
- **Topic:** Optics & Waves
- **Difficulty:** 2 (Medium)
- **Question:** For any wave traveling at speed $v$ with frequency $f$ and wavelength $\lambda$, which wave equation holds true?
- **Options:**
  - [x] A) $v = f \lambda$
  - [ ] B) $v = \frac{f}{\lambda}$
  - [ ] C) $v = \frac{\lambda}{f^2}$
  - [ ] D) $v = f + \lambda$
- **Correct Index:** 0
- **Explanation:** Wave speed equals frequency multiplied by wavelength: $v = f\lambda$.

### phys_19
- **Topic:** Mechanics
- **Difficulty:** 2 (Medium)
- **Question:** If the net force acting on a moving object is exactly zero, what describes its motion?
- **Options:**
  - [x] A) It moves with constant velocity in a straight line
  - [ ] B) It immediately stops moving
  - [ ] C) It continuously accelerates
  - [ ] D) It moves in a circle with constant speed
- **Correct Index:** 0
- **Explanation:** By Newton's First Law, when $\Sigma F = 0$, acceleration is zero ($a = 0$), so the object maintains constant velocity (speed and direction).

### phys_20
- **Topic:** Fluids
- **Difficulty:** 2 (Medium)
- **Question:** What physical law states that an increase in pressure applied to an enclosed fluid is transmitted undiminished throughout the fluid?
- **Options:**
  - [x] A) Pascal's Principle
  - [ ] B) Bernoulli's Principle
  - [ ] C) Boyle's Law
  - [ ] D) Torricelli's Law
- **Correct Index:** 0
- **Explanation:** Pascal's Principle explains hydraulic systems: pressure applied to a confined fluid propagates uniformly in all directions.

### phys_21
- **Topic:** Thermodynamics
- **Difficulty:** 2 (Medium)
- **Question:** Which law of thermodynamics states that the total entropy of an isolated system always increases over time?
- **Options:**
  - [x] A) Second Law of Thermodynamics
  - [ ] B) First Law of Thermodynamics
  - [ ] C) Zeroth Law of Thermodynamics
  - [ ] D) Third Law of Thermodynamics
- **Correct Index:** 0
- **Explanation:** The Second Law establishes that natural thermodynamic processes are irreversible and drive an isolated system toward maximum entropy.

### phys_22
- **Topic:** Mechanics
- **Difficulty:** 2 (Medium)
- **Question:** What is the kinetic energy of a $2\,\text{kg}$ mass moving at a speed of $4\,\text{m/s}$?
- **Options:**
  - [x] A) $16\,\text{J}$
  - [ ] B) $8\,\text{J}$
  - [ ] C) $32\,\text{J}$
  - [ ] D) $4\,\text{J}$
- **Correct Index:** 0
- **Explanation:** $KE = \frac{1}{2}mv^2 = \frac{1}{2}(2\,\text{kg})(4\,\text{m/s})^2 = 1 \cdot 16 = 16\,\text{Joules}$.

### phys_23
- **Topic:** Electromagnetism
- **Difficulty:** 3 (Hard)
- **Question:** Which law states that an induced electromotive force (EMF) is proportional to the time rate of change of magnetic flux through the circuit?
- **Options:**
  - [x] A) Faraday's Law of Electromagnetic Induction
  - [ ] B) Ampere's Circuital Law
  - [ ] C) Coulomb's Inverse-Square Law
  - [ ] D) Gauss's Law for Magnetism
- **Correct Index:** 0
- **Explanation:** Faraday's Law ($\mathcal{E} = -\frac{d\Phi_B}{dt}$) dictates how dynamic magnetic fields generate electrical voltages, serving as the basis for generators and transformers.

### phys_24
- **Topic:** Modern Physics
- **Difficulty:** 3 (Hard)
- **Question:** In the photoelectric effect, what parameter of incident light determines whether electrons are ejected from a metal surface?
- **Options:**
  - [x] A) The frequency of the light (must exceed threshold frequency $f_0$)
  - [ ] B) The intensity of the light beam only
  - [ ] C) The duration of illumination
  - [ ] D) The polarization angle only
- **Correct Index:** 0
- **Explanation:** Einstein's photoelectric theory demonstrated that photon energy depends on frequency ($E = hf$). Below the threshold frequency $f_0$, no photoelectrons are emitted regardless of beam intensity.

### phys_25
- **Topic:** Mechanics & Gravitation
- **Difficulty:** 3 (Hard)
- **Question:** If the distance between two masses is doubled, how does the gravitational attractive force between them change according to Newton's Law of Universal Gravitation?
- **Options:**
  - [x] A) It decreases to $\frac{1}{4}$ of its initial value
  - [ ] B) It decreases to $\frac{1}{2}$ of its initial value
  - [ ] C) It stays the same
  - [ ] D) It increases by a factor of 4
- **Correct Index:** 0
- **Explanation:** Gravitational force obeys an inverse-square law: $F = G\frac{m_1 m_2}{r^2}$. Doubling the separation distance ($r \to 2r$) reduces the force by $(2)^2 = 4$, making it $\frac{1}{4}F$.
