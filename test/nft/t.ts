import metadataList from "./mockMetadatalist.json";

metadataList.forEach((item) => {
  if (item.type == "Degens") {
    console.log({
      tokenId: item.token_id,
      heroId: item.hero_id,
      type: item.type,
    });
  }
});
