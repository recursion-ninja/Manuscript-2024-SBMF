/****
  *
  * LTL: FSU (Future Secrecy with Updates)
  *
  * Never corrupt a hoarder implies never learn the past
  *
****/
(
    []( CGKA@move_corrupt -> !( CheckBit( hoardPrior, targetID ) ) )
)
    ->
(
    []( !( learnedLegacyKey ) )
)
