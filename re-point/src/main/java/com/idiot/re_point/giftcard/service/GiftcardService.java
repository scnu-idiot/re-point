// com.idiot.re_point.giftcard.service.GiftcardService.java
package com.idiot.re_point.giftcard.service;

import com.google.cloud.firestore.*;
import com.idiot.re_point.giftcard.model.Giftcard;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class GiftcardService {
    private final Firestore firestore;

    private CollectionReference col() {
        return firestore.collection("giftcards");
    }

    public void upsert(String cardId, Giftcard card) throws ExecutionException, InterruptedException {
        col().document(cardId).set(card.toMap(), SetOptions.merge()).get();
    }

    public void seedDefaults() throws ExecutionException, InterruptedException {
        List<Giftcard> items = List.of(
                Giftcard.builder().cardId("card_5000").cardName("지역상품권 5천원권").cardValue(5000).stock(9999).active(true).build(),
                Giftcard.builder().cardId("card_10000").cardName("지역상품권 1만원권").cardValue(10000).stock(9999).active(true).build(),
                Giftcard.builder().cardId("card_20000").cardName("지역상품권 2만원권").cardValue(20000).stock(9999).active(true).build(),
                Giftcard.builder().cardId("card_30000").cardName("지역상품권 3만원권").cardValue(30000).stock(9999).active(true).build(),
                Giftcard.builder().cardId("card_50000").cardName("지역상품권 5만원권").cardValue(50000).stock(9999).active(true).build()
        );
        WriteBatch batch = firestore.batch();
        for (Giftcard g : items) {
            batch.set(col().document(g.getCardId()), g.toMap(), SetOptions.merge());
        }
        batch.commit().get();
    }
}