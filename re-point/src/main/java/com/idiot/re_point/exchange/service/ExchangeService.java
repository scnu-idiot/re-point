package com.idiot.re_point.exchange.service;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.idiot.re_point.exchange.dto.RedeemResponse;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.RandomStringUtils;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class ExchangeService {

    private final Firestore firestore;

    private CollectionReference users()     { return firestore.collection("users"); }
    private CollectionReference giftcards() { return firestore.collection("giftcards"); }
    private CollectionReference exchanges() { return firestore.collection("exchanges"); }
    private CollectionReference points()    { return firestore.collection("points"); }

    /**
     * 상품권 교환
     * - giftcards/{cardId} 확인 (active && stock>0)
     * - users/{uid}.point 확인 (>= card_value)
     * - 트랜잭션:
     *    * 유저 포인트 차감
     *    * giftcard 재고 -1
     *    * exchanges 문서 생성 (코드 발급)
     *    * points 히스토리(spend) 문서 생성
     */
    public RedeemResponse redeem(String uid, String cardId)
            throws ExecutionException, InterruptedException {

        return firestore.runTransaction(tx -> {
            DocumentReference userDoc = users().document(uid);
            DocumentSnapshot  userSnap = tx.get(userDoc).get();
            if (!userSnap.exists()) throw new RuntimeException("User not found: " + uid);

            Long userPoint = userSnap.getLong("point");
            if (userPoint == null) userPoint = 0L;

            DocumentReference cardDoc = giftcards().document(cardId);
            DocumentSnapshot  cardSnap = tx.get(cardDoc).get();
            if (!cardSnap.exists()) throw new RuntimeException("Giftcard not found: " + cardId);

            Boolean active = cardSnap.getBoolean("active");
            Long stock     = cardSnap.getLong("stock");
            Long cardValue = cardSnap.getLong("card_value");
            String cardName= cardSnap.getString("card_name");

            if (active == null || !active) throw new RuntimeException("Giftcard inactive: " + cardId);
            if (stock == null || stock <= 0) throw new RuntimeException("Giftcard out of stock: " + cardId);
            if (cardValue == null || cardValue <= 0) throw new RuntimeException("Invalid card_value");

            if (userPoint < cardValue) throw new RuntimeException("Not enough points");

            long balanceAfter = userPoint - cardValue;

            // 1) 유저 포인트 차감
            tx.update(userDoc, "point", balanceAfter, "updated_at", Timestamp.now());

            // 2) 기프트카드 재고 -1
            tx.update(cardDoc, "stock", stock - 1);

            // 3) 교환 문서 생성
            String code = makeGiftCode();
            Map<String, Object> ex = new HashMap<>();
            ex.put("user_id", uid);
            ex.put("card_id", cardId);
            ex.put("points_used", cardValue);
            ex.put("status", "COMPLETED");
            ex.put("exchange_date", Timestamp.now());
            Map<String, Object> delivery = new HashMap<>();
            delivery.put("code", code);
            delivery.put("received", "COMPLETED");
            ex.put("delivery_info", delivery);
            ex.put("card_name", cardName);
            ex.put("card_value", cardValue);

            DocumentReference exDoc = exchanges().document();
            tx.set(exDoc, ex);

            // 4) 포인트 히스토리(spend)
            Map<String, Object> ph = new HashMap<>();
            ph.put("uid", uid);
            ph.put("type", "spend");
            ph.put("title", "상품권 교환");
            ph.put("detail", cardName == null ? cardId : cardName);
            ph.put("amount", -cardValue);
            ph.put("balance_after", balanceAfter);
            ph.put("created_at", Timestamp.now());
            ph.put("card_id", cardId);

            DocumentReference phDoc = points().document();
            tx.set(phDoc, ph);

            return RedeemResponse.builder()
                    .exchangeId(exDoc.getId())
                    .code(code)
                    .pointsUsed(cardValue)
                    .balanceAfter(balanceAfter)
                    .build();
        }).get();
    }

    private String makeGiftCode() {
        // 대문자/숫자 4-4-4 형태 예: 9K2F-ABCD-7M3Q
        return RandomStringUtils.randomAlphanumeric(4).toUpperCase() + "-" +
                RandomStringUtils.randomAlphanumeric(4).toUpperCase() + "-" +
                RandomStringUtils.randomAlphanumeric(4).toUpperCase();
    }
}