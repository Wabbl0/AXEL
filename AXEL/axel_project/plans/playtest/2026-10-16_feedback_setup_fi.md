# Palautelomakkeen käyttöönotto (suomeksi)

Tämä tehdään vain kerran. Aikaa menee noin 10 minuuttia.

Pelin palautelomake lähettää vastaukset Google Sheets -taulukkoon. Taulukko tarvitsee pienen "vastaanottajan" (Apps Script). Vastaanottaja saa oman nettiosoitteen, ja se osoite liitetään peliin. Vertauskuva: rakennat postilaatikon ja annat pelille sen osoitteen.

Google näyttää valikot joko suomeksi tai englanniksi. Siksi kummatkin nimet ovat alla, esimerkiksi **Laajennukset** (Extensions).

## Osa 1: Tee taulukko

1. Avaa selaimessa https://sheets.google.com.
2. Kirjaudu sisään Google-tililläsi, jos sitä pyydetään.
3. Klikkaa isoa **+**-ruutua (**Tyhjä** / Blank). Uusi tyhjä taulukko aukeaa.
4. Klikkaa vasemmassa yläkulmassa tekstiä **Nimetön laskentataulukko** (Untitled spreadsheet).
5. Kirjoita nimeksi `AXEL Feedback` ja paina Enter.

## Osa 2: Liitä koodi

6. Klikkaa ylävalikosta **Laajennukset** (Extensions).
7. Klikkaa **Apps Script**. Uusi välilehti aukeaa.
8. Uudella välilehdellä näkyy valmiina vähän koodia (`function myFunction() {...}`).
9. Klikkaa koodin sisään ja valitse kaikki: **Ctrl + A**.
10. Poista se: **Delete**.
11. Avaa tietokoneeltasi tiedosto `AXEL/axel_project/tools/feedback/Code.gs`. Esimerkiksi VS Code tai Muistio käy.
12. Valitse siellä kaikki (**Ctrl + A**) ja kopioi (**Ctrl + C**).
13. Palaa Apps Script -välilehdelle ja liitä (**Ctrl + V**).
14. Tallenna levykkeen kuvasta tai painamalla **Ctrl + S**.

## Osa 3: Rakenna välilehdet ja kaaviot

15. Koodin yläpuolella on pudotusvalikko, jossa lukee funktion nimi. Valitse siitä **setup**.
16. Klikkaa sen vieressä **Suorita** (Run).
17. Google pyytää lupaa. Klikkaa **Tarkista käyttöoikeudet** (Review permissions).
18. Valitse oma Google-tilisi.
19. Jos näkyy varoitus "Google ei ole vahvistanut tätä sovellusta", se on normaalia, koska teit sovelluksen itse. Klikkaa **Lisäasetukset** (Advanced).
20. Klikkaa **Siirry kohteeseen AXEL Feedback (ei turvallinen)** (Go to ... (unsafe)).
21. Klikkaa **Salli** (Allow).
22. Odota, kunnes alareunassa lukee **Suoritus valmis** (Execution completed).
23. Palaa taulukon välilehdelle. Alareunassa on nyt välilehdet **Charts, Responses, Comments, GameData, Fights, Spins**.
24. Google Driven samaan kansioon on myös syntynyt dokumentti **AXEL Feedback Comments**. Sinne tulevat kaikki kirjoitetut kommentit.

## Osa 4: Anna vastaanottajalle nettiosoite

25. Palaa Apps Script -välilehdelle.
26. Klikkaa oikeasta yläkulmasta sinistä nappia **Ota käyttöön** (Deploy).
27. Klikkaa **Uusi käyttöönotto** (New deployment).
28. Klikkaa vasemmalla **rattaan kuvaa** ja valitse **Verkkosovellus** (Web app).
29. Kirjoita kuvaukseksi esimerkiksi `AXEL palaute`.
30. Valitse kohtaan **Suorita käyttäjänä** (Execute as): **Minä** (Me).
31. Valitse kohtaan **Kenellä on käyttöoikeus** (Who has access): **Kaikki** (Anyone).
    Tämä on tärkeää. Muuten testaajien peli ei saa lähetettyä vastauksia.
32. Klikkaa **Ota käyttöön** (Deploy).
33. Näkyviin tulee **Verkkosovelluksen URL-osoite** (Web app URL), joka päättyy `/exec`. Klikkaa **Kopioi** (Copy).

## Osa 5: Liitä osoite peliin

34. Avaa VS Codessa tiedosto `AXEL/axel_project/scripts/autoload/axel_feedback.gd`.
35. Etsi rivi 7: `const ENDPOINT_URL := ""`.
36. Liitä osoite lainausmerkkien väliin. Rivi näyttää tältä:
    `const ENDPOINT_URL := "https://script.google.com/macros/s/.../exec"`
37. Tallenna: **Ctrl + S**.

## Osa 6: Testaa

38. Käynnistä peli Godotissa (F5).
39. Klikkaa päävalikossa alareunan liikkuvaa palkkia.
40. Valitse ensimmäiseen kysymykseen numero ja paina **Send**.
41. Lomakkeessa lukee "Thank you! Your feedback was sent."
42. Avaa taulukko ja katso **Responses**-välilehteä. Siinä on uusi rivi.
    Editorista lähetetty vastaus on merkitty `debug = yes`. Siksi se näkyy kaavioissa vain, jos ruksaat **Charts**-välilehdellä kohdan **Include debug builds**.

## Hyvä tietää

- **Excel-tiedosto:** valitse taulukossa **Tiedosto → Lataa → Microsoft Excel (.xlsx)** (File → Download).
- **Kaaviot:** **Charts**-välilehdellä voit valita solusta **B1** version, jonka vastaukset näytetään, tai valita **All**.
- **Jos muutat Code.gs-tiedostoa myöhemmin:** liitä uusi koodi samaan Apps Scriptiin. Valitse sitten **Ota käyttöön → Hallinnoi käyttöönottoja** (Manage deployments), klikkaa **kynää** ja valitse **Versio: Uusi versio** (New version). Näin nettiosoite pysyy samana, eikä peliä tarvitse muuttaa.
- **Jos testaajalla ei ole nettiä:** vastaus tallentuu hänen koneelleen ja lähtee automaattisesti seuraavalla käynnistyskerralla.
- **Salasana (`TOKEN`):** sama sana on sekä `Code.gs`-tiedostossa että `axel_feedback.gd`:ssä. Jos vaihdat sen, vaihda molempiin.
