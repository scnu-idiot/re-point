package com.idiot.re_point.exchange.service;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.idiot.re_point.exchange.dto.ExchangeResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class ExchangeService {

    private final Firestore firestore;
    private static final SecureRandom RND = new SecureRandom();

    private static String randomCode() {
        // 간단한 10자리 코드 예: AB12-3CD4E
        String alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) sb.append(alphabet.charAt(RND.nextInt(alphabet.length())));
        sb.insert(4, '-');
        return sb.toString();
    }

    public ExchangeResponse exchangeGiftcard(String uid, String cardId)
            throws ExecutionException, InterruptedException {

        DocumentReference userRef = firestore.collection("users").document(uid);
        DocumentReference cardRef = firestore.collection("giftcards").document(cardId);
        CollectionReference exchangesCol = firestore.collection("exchanges");

        // 카드 존재/금액 확인
        DocumentSnapshot cardSnap = cardRef.get().get();
        if (!cardSnap.exists()) {
            throw new IllegalArgumentException("Giftcard not found: " + cardId);
        }
        Number cardValueNum = (Number) cardSnap.get("card_value");
        long pointsToUse = cardValueNum == null ? 0L : cardValueNum.longValue();
        if (pointsToUse <= 0) throw new IllegalStateException("Invalid card value.");

        // 트랜잭션: 포인트 차감 + 교환문서 생성
        return firestore.runTransaction(tx -> {
            // 1) 유저 조회
            DocumentSnapshot userSnap = tx.get(userRef).get();
            if (!userSnap.exists()) throw new IllegalStateException("User not found: " + uid);

            Number curPointNum = (Number) userSnap.get("point");
            long curPoint = curPointNum == null ? 0L : curPointNum.longValue();

            if (curPoint < pointsToUse) {
                throw new IllegalStateException("Not enough points. balance=" + curPoint);
            }

            // 2) 차감 후 잔액
            long newBalance = curPoint - pointsToUse;

            // 3) 코드 생성
            String code = randomCode();

            // 4) exchanges 문서 생성
            Map<String, Object> exch = new HashMap<>();
            exch.put("user_id", uid);
            exch.put("card_id", cardId);
            exch.put("points_used", pointsToUse);
            exch.put("status", "COMPLETED");
            exch.put("exchange_date", Timestamp.ofTimeSecondsAndNanos(
                    Instant.now().getEpochSecond(), Instant.now().getNano()));

            Map<String, Object> delivery = new HashMap<>();
            delivery.put("code", code);
            delivery.put("received", "COMPLETED"); // 코드형 상품권이라 즉시 수령 처리
            exch.put("delivery_info", delivery);

            DocumentReference newExRef = exchangesCol.document(); // auto id
            tx.set(newExRef, exch, SetOptions.merge());

            // 5) 유저 포인트 차감
            Map<String, Object> patch = new HashMap<>();
            patch.put("point", newBalance);
            patch.put("updated_at", Timestamp.ofTimeSecondsAndNanos(
                    Instant.now().getEpochSecond(), Instant.now().getNano()));
            tx.update(userRef, patch);

            return new ExchangeResponse(newExRef.getId(), code, pointsToUse, newBalance, "COMPLETED");
        }).get();
    }
}