# Noter

Loft deterioation

Der er 4 stadier på en loft tile:

1. Ingen hjørner er beskadigede.
2. To hjørner er beskadigede.
    2a. To hjørner på samme kant, hvor tilen kan have en arbitrær vinkel på loftet, men to knuder sidder stadig på loftet.
3. Tre hjørner er beskadigede.
    3a. Tilen hænger med center of mass under knuden, så den bare hænger og dingler. Eventuel animation.
4. Alle fire hjørner er beskadigede.
    4a. Tilen falder ned og ligger på gulvet.
    4b. Tilen falder ned og bliver ødelagt.

Camera movement effect
Det er ikke velocity vi skulle putte brownian motion på, men the derivative af det. Vi skulle holde en anden vektor vi putter brownian motion på, og så lægge den vektor på velocity hver tick.

## Gameplay Loop

Starter i en elevator, man skal gå ud af. Efter hver dag går man tilbage til elevatoren for at tage hjem. Det tvinger en til at gå igennem kontorets environment, hvor ting kan ske.

## Random events

En loftlampe længere væk, over en anden desk, er pludselig gået ud. Udforsk det.
En cubicle der pludselig mangler.
Ting der går i stykker; lamper fra loftet hænger og dingler, skærme der blinker, printere der spytter papir ud, posters der falder ned fra væggen.
En lampe der pludselig springer. De begynder langsomt at lave flere lyde hver iteration, blinke mere og mere, indtil de springer.

## Folder Race

Bugs:
Kan kun lukke den sidst åbnede folder.
Mus har meget indput lag.

Todo:
Clamp antal folder mellem 2 og 5.
Hav filer randomly i stedet for foldere kun - det er jo filer man leder efter. Navnet på den fil man leder efter skal være let genkendeligt i forhold til de andre fylde-filer.
Ny cursor grafik.
